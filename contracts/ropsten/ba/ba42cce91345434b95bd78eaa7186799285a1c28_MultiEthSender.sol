pragma solidity ^0.4.22;

contract Ownable {
    
    address public owner;
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
    
}

contract MultiEthSender is Ownable {
    
    event Send(
        uint256 _amount, 
        address indexed _receiver
    );
    event ExamFinished();
    
    address public wallet;
    bool public examFinished = false;
    mapping (address => uint256) public deposits;
    
    modifier canExam() {
        require(!examFinished, "Exam has finished");
        _;
    }
    modifier hasMoney() {
        require(balance() > 0, "Account has no money");
        _;
    }
    modifier atLeastOneEther(uint256 amount) {
        require(amount >= 1 ether, "At least 1 Ether");
        _;
    }
    modifier atLeastOneWei() {
        require(msg.value > 1, "At least 1 Wei");
        _;
    }

    constructor(address _wallet) public {
        require(_wallet != address(0));

        wallet = _wallet;
    }
    
    function multiSendEth(uint256 amount, address[] list) atLeastOneEther(amount) canExam hasMoney public returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            address(list[i]).transfer(amount);
            
            emit Send(
                amount,
                list[i]
            );
        }
    }
    
    function () external payable {
        deposit(msg.sender);
    }
    
    function deposit(address boss) atLeastOneWei public payable {
        deposits[boss] += msg.value;
    }
    
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function forwardMoney() onlyOwner hasMoney public payable {
        wallet.transfer(msg.value);
    }
    
    function finishExam() onlyOwner canExam public returns (bool) {
        examFinished = true;
        emit ExamFinished();
        return true;
    }
    
}