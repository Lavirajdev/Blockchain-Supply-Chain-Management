// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    address public admin;
    
    enum Role { Supplier, Manufacturer, Distributor }
    
    struct Participant {
        address id;
        Role role;
    }
    
    struct Product {
        uint productId;
        string name;
        address supplier;
        address manufacturer;
        address distributor;
        bool qualityChecked;
        uint createdAt;
        uint updatedAt;
    }
    
    struct IoTData {
        uint timestamp;
        string location;
        uint temperature;
        bool valid;
    }
    
    mapping(address => Participant) public participants;
    mapping(uint => Product) public products;
    mapping(uint => IoTData[]) public productIoTData;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }
    
    modifier onlyRole(Role role) {
        require(participants[msg.sender].role == role, "Unauthorized role");
        _;
    }
    
    event ProductRegistered(uint productId, address indexed supplier);
    event ProductTransferred(uint productId, address indexed from, address indexed to, string stage);
    event QualityChecked(uint productId, address indexed checker);
    event PaymentReleased(uint productId, address indexed receiver);
    
    constructor() {
        admin = msg.sender;
    }

    // Register a participant in the supply chain
    function registerParticipant(address _address, Role _role) public onlyAdmin {
        participants[_address] = Participant(_address, _role);
    }

    // Supplier adds a new product to the blockchain
    function registerProduct(uint _productId, string memory _name) public onlyRole(Role.Supplier) {
        Product memory product = Product({
            productId: _productId,
            name: _name,
            supplier: msg.sender,
            manufacturer: address(0),
            distributor: address(0),
            qualityChecked: false,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        products[_productId] = product;
        emit ProductRegistered(_productId, msg.sender);
    }

    // Manufacturer receives the product from the supplier and updates details
    function updateManufacturer(uint _productId) public onlyRole(Role.Manufacturer) {
        Product storage product = products[_productId];
        require(product.supplier != address(0), "Product not found");
        require(product.manufacturer == address(0), "Already with manufacturer");

        product.manufacturer = msg.sender;
        product.updatedAt = block.timestamp;
        emit ProductTransferred(_productId, product.supplier, msg.sender, "Manufacturer");
    }

    // Distributor receives the product and logs receipt
    function updateDistributor(uint _productId) public onlyRole(Role.Distributor) {
        Product storage product = products[_productId];
        require(product.manufacturer != address(0), "Product not with manufacturer");
        require(product.distributor == address(0), "Already with distributor");

        product.distributor = msg.sender;
        product.updatedAt = block.timestamp;
        emit ProductTransferred(_productId, product.manufacturer, msg.sender, "Distributor");
    }

    // Log IoT data (e.g., temperature, location) for a product
    function logIoTData(uint _productId, string memory _location, uint _temperature) public {
        require(products[_productId].productId != 0, "Product not registered");

        IoTData memory data = IoTData({
            timestamp: block.timestamp,
            location: _location,
            temperature: _temperature,
            valid: true
        });

        productIoTData[_productId].push(data);
    }

    // Quality check by manufacturer or distributor, updates the status on the blockchain
    function qualityCheck(uint _productId) public onlyRole(Role.Manufacturer) {
        Product storage product = products[_productId];
        require(product.manufacturer == msg.sender, "Unauthorized checker");
        
        product.qualityChecked = true;
        emit QualityChecked(_productId, msg.sender);
    }

    // Automated payment release on successful quality check and delivery
    function releasePayment(uint _productId) public {
        Product storage product = products[_productId];
        require(product.qualityChecked, "Quality check not passed");
        require(product.distributor != address(0), "Product not with distributor");

        payable(product.supplier).transfer(1 ether); // Sample payment; adjust as needed
        emit PaymentReleased(_productId, product.supplier);
    }
}
