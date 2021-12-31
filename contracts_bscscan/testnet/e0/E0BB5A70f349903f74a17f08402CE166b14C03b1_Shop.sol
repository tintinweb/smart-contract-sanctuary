// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Shop {
    // owner of this contract
    address public owner;

    // bank balance
    uint256 public balance;

    // bank account info
    struct BankAccount {
        string accountNumber;
        string ownerPhoneNumber;
        uint256 balance;
        address accountAddress;
    }

    //struct data of a transaction
    struct Transaction {
        string code;
        string fromAccountNumber;
        string toAccountNumber;
        uint256 amount;
        uint256 fee;
        uint256 timeStamp;
    }

    struct User {
        uint256 id;
        string name;
        string phone;
        string email;
        uint256 timeStamp;
    }

    struct Product {
        uint256 id;
        string title;
        uint256 price;
        uint256 size;
        string description;
        string image;
        string color;
        string prodcutAddress;
        uint256 timeStamp;
    }

    struct Order {
        uint256 totalPrice;
        string orderAddress;
        string details;
        string name;
        string phone;
        uint256 timeStamp;
    }

    // mapping from account number to account
    mapping(string => BankAccount) public bankAccounts;

    // mapping from code to transaction
    mapping(string => Transaction) public transactions;

    // mapping from id to order
    mapping(uint256 => Order) public orders;
    mapping(uint256 => uint256) public orderToOwner;

    // mapping from id to product
    mapping(uint256 => Product) public products;

    // mapping from id to user
    mapping(uint256 => User) public users;

    constructor() {
        owner = msg.sender;
    }

    // owner functions
    function createUser(
        uint256 _id,
        string memory _name,
        string memory _phone,
        string memory _email,
        uint256 _timeStamp
    ) public onlyOwner {
        //create user
        users[_id] = User({
            id: _id,
            name: _name,
            phone: _phone,
            email: _email,
            timeStamp: _timeStamp
        });
    }

    function getUser(uint256 _id) public view onlyOwner returns (User memory) {
        return users[_id];
    }

    function createProduct(
        uint256 _id,
        string memory _title,
        uint256 _price,
        uint256 _size,
        string memory _description,
        string memory _image,
        string memory _color,
        string memory _prodcutAddress,
        uint256 _timeStamp
    ) public onlyOwner {
        //create user
        products[_id] = Product({
            id: _id,
            title: _title,
            price: _price,
            size: _size,
            description: _description,
            image: _image,
            color: _color,
            prodcutAddress: _prodcutAddress,
            timeStamp: _timeStamp
        });
    }

    function getProduct(uint256 _id)
        public
        view
        onlyOwner
        returns (Product memory)
    {
        return products[_id];
    }

    function addOrder(
        uint256 _id,
        uint256 _userId,
        uint256 _totalPrice,
        string memory _orderAddress,
        string memory _details,
        string memory _name,
        string memory _phone,
        uint256 _timeStamp
    ) public onlyOwner {
        //create order
        orders[_id] = Order({
            totalPrice: _totalPrice,
            orderAddress: _orderAddress,
            details: _details,
            name: _name,
            phone: _phone,
            timeStamp: _timeStamp
        });
        orderToOwner[_id] = _userId;
    }

    function getOrder(uint256 _id)
        public
        view
        onlyOwner
        returns (Order memory)
    {
        return orders[_id];
    }

    function addBalance(uint256 amount) public onlyOwner {
        balance += amount;
    }

    function addAccountBalance(
        string memory code,
        string memory accountNumber,
        uint256 amount,
        uint256 timeStamp
    ) public onlyOwner balanceValidate(amount) transactionCodeNotExists(code) {
        balance -= amount;
        bankAccounts[accountNumber].balance += amount;

        //create transaction
        transactions[code] = Transaction({
            code: code,
            fromAccountNumber: "000000000000",
            toAccountNumber: accountNumber,
            amount: amount,
            fee: 0,
            timeStamp: timeStamp
        });
    }

    function changeAddressOfAccount(
        string memory accountNumber,
        address newAddress
    ) public onlyOwner accountExists(accountNumber) {
        bankAccounts[accountNumber].accountAddress = newAddress;
    }

    // user functions
    function createAccount(
        string memory accountNumber,
        string memory ownerPhoneNumber,
        address accountAddress
    ) public accountNotExists(accountNumber) {
        bankAccounts[accountNumber] = BankAccount({
            accountNumber: accountNumber,
            ownerPhoneNumber: ownerPhoneNumber,
            balance: 0,
            accountAddress: accountAddress
        });
    }

    function transfer(
        string memory code,
        string memory fromAccount,
        string memory toAccount,
        uint256 fee,
        uint256 amount,
        uint256 timeStamp
    )
        public
        accountValidateTransfer(fromAccount, amount, fee)
        accountExists(toAccount)
        transactionCodeNotExists(code)
    {
        bankAccounts[fromAccount].balance -= amount;
        bankAccounts[toAccount].balance += amount;

        bankAccounts[fromAccount].balance -= fee;
        balance += fee;

        //create transaction
        transactions[code] = Transaction({
            code: code,
            fromAccountNumber: fromAccount,
            toAccountNumber: toAccount,
            amount: amount,
            fee: fee,
            timeStamp: timeStamp
        });
    }

    // modifiers

    // modifier that use to require caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // modifier that use to make sure account not exists
    modifier accountNotExists(string memory accountNumber) {
        string memory empty = "";
        require(
            keccak256(bytes(bankAccounts[accountNumber].accountNumber)) ==
                keccak256(bytes(empty))
        );
        _;
    }

    // modifier that use to make sure account exists
    modifier accountExists(string memory accountNumber) {
        string memory moneyBaseAccount = "000000000000";

        require(
            keccak256(bytes(bankAccounts[accountNumber].accountNumber)) ==
                keccak256(bytes(accountNumber))
        );
        _;
    }

    // modifier that use to make sure account have right secure hash
    // and valid amount for transfer
    modifier accountValidateTransfer(
        string memory accountNumber,
        uint256 amount,
        uint256 fee
    ) {
        require(
            bankAccounts[accountNumber].accountAddress == msg.sender &&
                bankAccounts[accountNumber].balance >= amount + fee
        );
        _;
    }

    // modifier that make sure bank balance have enough money
    // to add account balance
    modifier balanceValidate(uint256 amount) {
        require(balance >= amount);
        _;
    }

    // modifier that make sure transaction
    // with code have not exist
    modifier transactionCodeNotExists(string memory code) {
        string memory empty = "";
        require(
            keccak256(bytes(transactions[code].code)) == keccak256(bytes(empty))
        );
        _;
    }
}