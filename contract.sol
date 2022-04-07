// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum Role {
    ADMIN,
    USER
}

contract RentManagerV1 {
    struct User {
        string username;
        bytes32 secretHash;
        Role role;
        bool exists;
    }
    mapping(address => User) users;
    mapping(string => address) userLogins;
    string[] userLoginsArray;

    modifier onlyExistingUser() {
        require(users[msg.sender].exists, "Access denied");
        _;
    }

    modifier onlyAdmin() {
        require(users[msg.sender].role == Role.ADMIN, "Access denied");
        _;
    }

    function register(string memory username, bytes32 secretHash) external {
        require(!users[msg.sender].exists, "You're already registered");
        require(
            !users[userLogins[username]].exists,
            "This username is already taken"
        );

        userLogins[username] = msg.sender;
        users[msg.sender] = User(username, secretHash, Role.USER, true);
        userLoginsArray.push(username);
    }

    function authenticate(string memory secret) external view returns (bool) {
        require(users[msg.sender].exists, "You're not registered");
        require(
            users[msg.sender].secretHash == keccak256(abi.encodePacked(secret))
        );
        return true;
    }
}

contract RentManagerV2 is RentManagerV1 {
    struct Object {
        address owner;
        uint256 id;
        uint256 totalArea;
        uint256 kitchenArea;
        bool exists;
    }
    mapping(uint256 => Object) objects;
    uint256[] objectIds;

    function newObject(
        address owner,
        uint256 totalArea,
        uint256 kitchenArea
    ) external {
        objects[objectIds.length] = Object(
            owner,
            objectIds.length,
            totalArea,
            kitchenArea,
            true
        );
        objectIds.push(objectIds.length);
    }

    function getObject(uint256 objectId)
        external
        view
        returns (
            address owner,
            uint256 id,
            uint256 totalArea,
            uint256 kitchenArea
        )
    {
        require(objects[objectId].exists, "Object does not exist");
        Object memory object = objects[objectId];
        return (object.owner, object.id, object.totalArea, object.kitchenArea);
    }

    function getObjectIds() external view returns (uint256[] memory) {
        return objectIds;
    }
}

contract RentManagerV3 is RentManagerV2 {
    struct Rent {
        uint256 id;
        uint256 objectId;
        uint256 creationDate;
        uint256 rentDurationInDays;
        uint256 pricePerDay;
        uint256 lastPaymentDate;
        address renter;
        bool borrowed;
        bool exists;
    }
    mapping(uint256 => Rent) rents;
    mapping(uint256 => uint256) rentIdsByObjectId;
    uint256[] rentIds;

    struct RentOffer {
        address offerer;
        uint256 rentId;
        uint256 creationDate;
        uint256 value;
        bool finished;
        bool exists;
    }
    mapping(uint256 => RentOffer) rentOffers;
    mapping(uint256 => uint256) rentOfferIdsByRentId;
    uint256[] rentOfferIds;

    function newRent(
        uint256 objectId,
        uint256 pricePerDay,
        uint256 rentDurationInDays
    ) external {
        Object memory object = objects[objectId];

        require(object.exists, "Object does not exist");
        require(object.owner == msg.sender, "Access denied");
        require(
            !rents[rentIdsByObjectId[objectId]].exists,
            "Rent for this object already exists"
        );

        rents[rentIds.length] = Rent(
            rentIds.length,
            objectId,
            block.timestamp,
            rentDurationInDays,
            pricePerDay,
            0,
            address(0),
            false,
            true
        );
        rentIdsByObjectId[objectId] = rentIds.length;
        rentIds.push(rentIds.length);
    }

    function getRent(uint256 rentId)
        external
        view
        returns (
            uint256 id,
            uint256 objectId,
            uint256 creationDate,
            uint256 rentDurationInDays,
            uint256 pricePerDay,
            uint256 lastPaymentDate,
            address renter,
            bool borrowed
        )
    {
        Rent memory rent = rents[rentId];
        require(rent.exists, "Rent does not exist");
        require(
            block.timestamp - rent.creationDate < 30 * 24 * 60 * 60,
            "Rent duration expired"
        );
        return (
            rentId,
            rent.objectId,
            rent.creationDate,
            rent.rentDurationInDays,
            rent.pricePerDay,
            rent.lastPaymentDate,
            rent.renter,
            rent.borrowed
        );
    }

    function getRentIds() external view returns (uint256[] memory) {
        return rentIds;
    }

    function borrowRent(uint256 rentId) external payable {
        Rent memory rent = rents[rentId];
        require(rent.exists, "Rent does not exist");
        require(!rent.borrowed, "This rent is already borrowed");
        require(
            block.timestamp - rent.creationDate < 30 * 24 * 60 * 60,
            "Rent duration expired"
        );
        require(
            msg.value == (rent.rentDurationInDays * rent.pricePerDay),
            "You should send exact amount of eth that is specified in rent"
        );

        rentOffers[rentOfferIds.length] = RentOffer(
            msg.sender,
            rentId,
            block.timestamp,
            msg.value,
            false,
            true
        );
        rentOfferIds.push(rentOfferIds.length);
        rentOfferIdsByRentId[rentId] = rentOfferIds.length;
    }

    function acceptRentOffer(uint256 rentOfferId) external view {
        RentOffer memory rentOffer = rentOffers[rentOfferId];
        Rent memory rent = rents[rentOffer.rentId];
        require(rentOffer.exists, "Rent offer does not exist");
        require(rent.renter == msg.sender, "Access denied");
        require(!rent.borrowed, "Rent already borrowed");
    }
}
