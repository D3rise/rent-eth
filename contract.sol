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
            users[msg.sender].secretHash == keccak256(abi.encodePacked(secret)),
            "Wrong secret"
        );
        return true;
    }

    constructor() {
        users[0xe4799f2721784962835B03e5D7e20a874933B782] = User(
            "admin",
            keccak256(abi.encodePacked("12345")),
            Role.ADMIN,
            true
        );
        userLogins["admin"] = 0xe4799f2721784962835B03e5D7e20a874933B782;
        userLoginsArray.push("admin");

        users[0xe4799f2721784962835B03e5D7e20a874933B782] = User(
            "danil",
            keccak256(abi.encodePacked("12345")),
            Role.ADMIN,
            true
        );
        userLogins["danil"] = 0xe4799f2721784962835B03e5D7e20a874933B782;
        userLoginsArray.push("danil");

        users[0xe4799f2721784962835B03e5D7e20a874933B782] = User(
            "nadya",
            keccak256(abi.encodePacked("12345")),
            Role.ADMIN,
            true
        );
        userLogins["nadya"] = 0xe4799f2721784962835B03e5D7e20a874933B782;
        userLoginsArray.push("nadya");

        users[0xe4799f2721784962835B03e5D7e20a874933B782] = User(
            "vova",
            keccak256(abi.encodePacked("12345")),
            Role.ADMIN,
            true
        );
        userLogins["vova"] = 0xe4799f2721784962835B03e5D7e20a874933B782;
        userLoginsArray.push("vova");

        users[0xe4799f2721784962835B03e5D7e20a874933B782] = User(
            "albina",
            keccak256(abi.encodePacked("12345")),
            Role.USER,
            true
        );
        userLogins["albina"] = 0xe4799f2721784962835B03e5D7e20a874933B782;
        userLoginsArray.push("albina");

        users[0xe4799f2721784962835B03e5D7e20a874933B782] = User(
            "maxim",
            keccak256(abi.encodePacked("12345")),
            Role.USER,
            true
        );
        userLogins["maxim"] = 0xe4799f2721784962835B03e5D7e20a874933B782;
        userLoginsArray.push("maxim");
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

    function getRentOfferIds() external view returns (uint256[] memory) {
        return rentOfferIds;
    }

    function getRentOffer(uint256 rentOfferId)
        external
        view
        returns (
            uint256 id,
            address offerer,
            uint256 rentId,
            uint256 creationDate,
            uint256 value,
            bool finished
        )
    {
        RentOffer memory rentOffer = rentOffers[rentOfferId];
        require(rentOffer.exists, "Rent offer does not exist");
        require(rents[rentOffer.rentId].exists, "Rent does not exist");
        require(
            objects[rents[rentOffer.rentId].objectId].owner == msg.sender ||
                rentOffer.offerer == msg.sender,
            "Access denied"
        );

        return (
            rentOfferId,
            rentOffer.offerer,
            rentOffer.rentId,
            rentOffer.creationDate,
            rentOffer.value,
            rentOffer.finished
        );
    }

    function acceptRentOffer(uint256 rentOfferId) external {
        RentOffer memory rentOffer = rentOffers[rentOfferId];
        Rent memory rent = rents[rentOffer.rentId];
        require(rentOffer.exists, "Rent offer does not exist");
        require(
            objects[rents[rentOffer.rentId].objectId].owner == msg.sender,
            "Access denied"
        );
        require(!rentOffer.finished, "Rent offer already finished");
        require(!rent.borrowed, "Rent already borrowed");

        rentOffers[rentOfferId].finished = true;
        payable(msg.sender).transfer(rentOffer.value);
        rents[rentOffer.rentId].borrowed = true;
        rents[rentOffer.rentId].lastPaymentDate = block.timestamp;
        rents[rentOffer.rentId].renter = rentOffer.offerer;
    }

    function denyRentOffer(uint256 rentOfferId) external {
        RentOffer memory rentOffer = rentOffers[rentOfferId];
        Rent memory rent = rents[rentOffer.rentId];
        Object memory object = objects[rent.objectId];
        require(rentOffer.exists, "Rent offer does not exist");
        require(object.owner == msg.sender, "Access denied");
        require(!rentOffer.finished, "Rent offer already finished");

        rentOffers[rentOfferId].finished = true;
        payable(rentOffer.offerer).transfer(rentOffer.value);
    }

    function cancelRentOffer(uint256 rentOfferId) external {
        RentOffer memory rentOffer = rentOffers[rentOfferId];
        require(rentOffer.exists, "Rent offer does not exist");
        require(!rentOffer.finished, "Rent offer is already finished");
        require(rentOffer.offerer == msg.sender, "Access denied");

        rentOffers[rentOfferId].finished = true;
        payable(msg.sender).transfer(rentOffer.value);
    }
}
