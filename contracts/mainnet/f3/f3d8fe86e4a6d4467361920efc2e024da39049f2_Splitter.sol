pragma solidity 0.6.4;


import "./SafeMath.sol";

interface Token {
    function symbol()
    external
    view
    returns (string memory);
    
    function totalSupply()
    external
    view
    returns (uint256);
    
    function balanceOf (address account)
    external
    view
    returns (uint256);

    function transfer (address recipient, uint256 amount)
    external
    returns (bool);
}

contract Splitter {

    using SafeMath for uint256;
    ///////////////////
    //EVENTS//
    ///////////////////

    event DistributedToken(
        uint256 timestamp,
        address indexed senderAddress,
        uint256 distributed,
        string indexed tokenSymbol
    );
    
    event DistributedEth(
        uint256 timestamp,
        address indexed senderAddress,
        uint256 distributed
    );

    /////////////////////
    //SETUP//
    /////////////////////
    address[] public tokens;
    uint256 public _maxTokens = 5;
    mapping(address => bool) public tokenAdded;
    
    uint256 public _gasLimit = 21000;
    
    address payable internal _p1 = 0xb9F8e9dad5D985dF35036C61B6Aded2ad08bd53f;//30%
    address payable internal _p2 = 0xe551072153c02fa33d4903CAb0435Fb86F1a80cb;//30%
    address payable internal _p3 = 0xc5f517D341c1bcb2cdC004e519AF6C4613A8AB2d;//20%
    address payable internal _p4 = 0x47705B509A4Fe6a0237c975F81030DAC5898Dc06;//15%
    address payable internal _p5 = 0x31101541339B4B3864E728BbBFc1b8A0b3BCAa45;//2.5%
    address payable internal _p6 = 0x3020De97a74f3A40378922f310020709BF77b7D7;//2.5%

    mapping(address => bool) private admins;

    modifier onlyAdmins(){
        require(admins[msg.sender], "not an admin");
        _;
    }
    
    constructor() public {
        admins[_p1] = true;
        admins[_p2] = true;
        admins[_p3] = true;
    }
    
    ////////////////////
    //DISTRIBUTE//
    ////////////////////

    //distribute all pre-defined tokens and eth
    function distributeAll() public {
        for(uint i = 0; i < tokens.length; i++){
            if(Token(tokens[i]).balanceOf(address(this)) > 199){
                distributeToken(tokens[i]);
            }
        }
        if(address(this).balance > 199){
            distributeEth();   
        }
    }

    //distribute any token in contract via address
    function distributeToken(address tokenAddress) public {
        Token _token = Token(tokenAddress);
        //get balance 
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 199, "value too low to distribute");
        //distribute
        uint256 half_percent = balance.div(200);
        uint256 two_percent = balance.mul(2).div(100);
        uint256 fifteen_percent = balance.mul(15).div(100);
        uint256 twenty_percent = balance.mul(20).div(100);
        uint256 thirty_percent = balance.mul(30).div(100);
        require(_token.transfer(_p1, thirty_percent));
        require(_token.transfer(_p2, thirty_percent));
        require(_token.transfer(_p3, twenty_percent));
        require(_token.transfer(_p4, fifteen_percent));
        require(_token.transfer(_p5, two_percent.add(half_percent)));
        require(_token.transfer(_p6, two_percent.add(half_percent)));

        emit DistributedToken(now, msg.sender, balance, _token.symbol());
    }

    //distribute ETH in contract
    function distributeEth() public payable {
        uint256 balance = 0;
        if(msg.value > 0){
            balance = msg.value.add(address(this).balance);
        }
        else{
            balance = address(this).balance;
        }
        require(balance > 199, "value too low to distribute");
        bool success = false;
        //distribute
        uint256 half_percent = balance.div(200);
        uint256 two_percent = balance.mul(2).div(100);
        uint256 fifteen_percent = balance.mul(15).div(100);
        uint256 twenty_percent = balance.mul(20).div(100);
        uint256 thirty_percent = balance.mul(30).div(100);
        (success, ) =  _p1.call{value:thirty_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p2.call{value:thirty_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p3.call{value:twenty_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p4.call{value:fifteen_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p5.call{value:two_percent.add(half_percent)}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p6.call{value:two_percent.add(half_percent)}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        emit DistributedEth(now, msg.sender, balance);
    }

    //optional fallback for eth sent to contract - auto distribute on payment
    receive() external payable {
        //distributeEth();    
    }

    /////////////////
    //MUTABLE//
    /////////////////

//add new token to splitter - used for distribute all
    function addToken(address tokenAddress)
        public
        onlyAdmins
    {
        require(tokenAddress != address(0), "invalid address");
        require(Token(tokenAddress).totalSupply() > 0, "invalid contract");
        require(!tokenAdded[tokenAddress], "token already exists");
        require(tokens.length < _maxTokens, "cannot add more tokens than _maxTokens");
        tokenAdded[tokenAddress] = true;
        tokens.push(tokenAddress);
    }

//define gas limit for eth distribution per transfer
    function setGasLimit(uint gasLimit)
        public
        onlyAdmins
    {
        require(gasLimit > 0, "gasLimit must be greater than 0");
        _gasLimit = gasLimit;
    }
    
}