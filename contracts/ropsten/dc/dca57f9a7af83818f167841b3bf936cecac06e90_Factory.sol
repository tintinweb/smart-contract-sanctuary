pragma solidity ^0.5.2;
contract Account {
    function create(address _owner) public returns(address payable);
}
contract Factory {
    address public creator;
    address payable public admin;
    address payable public feeAddress;
    uint256 public fee;
    constructor(address _creator, uint256 _fee) public {
        admin = msg.sender;
        creator = _creator;
        feeAddress = Account(_creator).create(msg.sender);
        fee = _fee;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function () external payable {
        create();
    }
    function create() public payable {
        require(msg.value >= fee);
        address payable n = Account(creator).create(msg.sender);
        if (msg.value > fee) n.transfer(msg.value - fee);
        feeAddress.transfer(fee);
    }
    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = address(uint160(newAdmin));
    }
    function changeFeeAddress(address newFeeAddress) public onlyAdmin {
        require(newFeeAddress != address(0) && address(this) != newFeeAddress);
        feeAddress = address(uint160(newFeeAddress));
    }
    function changeFee(uint256 newFee) public onlyAdmin {
        require(newFee >= 1 finney);
        fee = newFee;
    }
    function changeCreator(address newCreator) public onlyAdmin {
        require(newCreator != address(0) && address(this) != newCreator);
        creator = newCreator;
    }
}