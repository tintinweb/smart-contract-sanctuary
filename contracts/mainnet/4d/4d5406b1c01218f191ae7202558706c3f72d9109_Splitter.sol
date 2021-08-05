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
    
    address payable internal _p1 = 0x6c28dc6529ba78fA3a0FEf408F2c982b074E41A5;//19.5%
    address payable internal _p2 = 0xe551072153c02fa33d4903CAb0435Fb86F1a80cb;//19.5%
    address payable internal _p3 = 0x0CC501fFd20e865d85867Fb5fbFb1259D1CAfD13;//11%
    address payable internal _p4 = 0x47705B509A4Fe6a0237c975F81030DAC5898Dc06;//10%
    address payable internal _p5 = 0xb9F8e9dad5D985dF35036C61B6Aded2ad08bd53f;//10%
    address payable internal _p6 = 0x4c7b5cB8240Dc5e5437FEf4AcC6445e47F3706A6;//5%
    address payable internal _p7 = 0xe2Ef81dCe4a639187B5c550da4A2ad89DB434C00;//5%
    address payable internal _p8 = 0xeC28143Fe252d0655C02768841Af4a7df1178ece;//3%
    address payable internal _p9 = 0xD6968Da8725D30738f926B9DE940a997C16b9a86;//3%
    address payable internal _p10 = 0x454f203260a74C0A8B5c0a78fbA5B4e8B31dCC63;//3%
    address payable internal _p11 = 0x92CA5D94704089Bc7a75Cd1dF5bBDb2CaA2D6855;//3%
    address payable internal _p12 = 0x5AFC90317463843b46c0645bf3fD1A82Bd3D8cFd;//3%
    address payable internal _p13 = 0xF80A891c1A7600dDd84b1F9d54E0b092610Ed804;//2%
    address payable internal _p14 = 0xf40e89F1e52A6b5e71B0e18365d539F5E424306f;//1%
    address payable internal _p15 = 0x65fBE695FE29897ADdECA149aBc3c8eb742EB204;//1%
    address payable internal _p16 = 0x860303910AF2519dE0945683c69620593818bC01;//1%

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
            if(Token(tokens[i]).balanceOf(address(this)) > 99){
                distributeToken(tokens[i]);
            }
        }
        if(address(this).balance > 99){
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
        uint256 percent = balance.div(100);
        uint256 half_percent = balance.div(200);
        uint256 two_percent = balance.mul(2).div(100);
        uint256 three_percent = balance.mul(3).div(100);
        uint256 five_percent = balance.mul(5).div(100);
        uint256 ten_percent = balance.mul(10).div(100);
        uint256 eleven_percent = balance.mul(11).div(100);
        uint256 nineteen_percent = balance.mul(19).div(100);
        require(_token.transfer(_p1, nineteen_percent.add(half_percent)));
        require(_token.transfer(_p2, nineteen_percent.add(half_percent)));
        require(_token.transfer(_p3, eleven_percent));
        require(_token.transfer(_p4, ten_percent));
        require(_token.transfer(_p5, ten_percent));
        require(_token.transfer(_p6, five_percent));
        require(_token.transfer(_p7, five_percent));
        require(_token.transfer(_p8, three_percent));
        require(_token.transfer(_p9, three_percent));
        require(_token.transfer(_p10, three_percent));
        require(_token.transfer(_p11, three_percent));
        require(_token.transfer(_p12, three_percent));
        require(_token.transfer(_p13, two_percent));
        require(_token.transfer(_p14, percent));
        require(_token.transfer(_p15, percent));
        require(_token.transfer(_p16, percent));
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
        uint256 percent = balance.div(100);
        uint256 half_percent = balance.div(200);
        uint256 two_percent = balance.mul(2).div(100);
        uint256 three_percent = balance.mul(3).div(100);
        uint256 five_percent = balance.mul(5).div(100);
        uint256 ten_percent = balance.mul(10).div(100);
        uint256 eleven_percent = balance.mul(11).div(100);
        uint256 nineteen_percent = balance.mul(19).div(100);
        (success, ) =  _p1.call{value:nineteen_percent.add(half_percent)}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p2.call{value:nineteen_percent.add(half_percent)}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p3.call{value:eleven_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p4.call{value:ten_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p5.call{value:ten_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p6.call{value:five_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p7.call{value:five_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p8.call{value:three_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p9.call{value:three_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p10.call{value:three_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p11.call{value:three_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p12.call{value:three_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p13.call{value:two_percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p14.call{value:percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p15.call{value:percent}{gas:_gasLimit}('');
        require(success, "Transfer failed");
        (success, ) =  _p16.call{value:percent}{gas:_gasLimit}('');
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