pragma solidity 0.5.9;

import './LynkpadToken.sol';
import './LynkPadIDO.sol';
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
contract Lynkpad {
    using SafeMath  for uint;
    address payable public owner;
    uint256 deployTokenCharges = 1 ether;
    struct Contractstruct {
        address tokenAddress;
        address pairAddress;
        string name;
        string symbol;
        uint256 decimals;
    }
    mapping(uint256 => Contractstruct) public DeployedContracts;
    uint256 numofContracts = 0;
    event tokenDeployed(string name, string _symbol,address indexed _contractAddress);
    event SellingPairCreated(address _contractAddress,uint256 _startBlock,uint256 _endBlock,uint256 _minprice,uint256 _maxprice,uint256 _totalTokenForSales,uint256 _tokenPereth);
    constructor() public {
        owner = msg.sender;
    }

    function deployToken(string memory _name, string memory _symbol, uint8 _decimals, address payable _owner,address _admin,uint256[7] memory _datas) public payable returns(address tokenaddress,address pairAddress) {
        //,uint256 _initialSupply,uint256  _startBlock,uint256 _endBlock,uint256 _minprice,uint256 _maxprice,uint256 _totalTokenForSales,uint256 _tokenPereth
        
        require(msg.value >= deployTokenCharges,"Invalid Charges Amount");
        bytes memory bytecode = type(LynkpadToken).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_name,_symbol,_decimals,_datas[0],_owner));
        assembly {
          tokenaddress := create2(0, add(bytecode, 32), mload(bytecode),salt)
        }
        LynkpadToken(tokenaddress).initialize(_name,_symbol,_decimals,_datas[0],_owner,_datas[5]);
        emit tokenDeployed(_name,_symbol,tokenaddress);
        Contractstruct memory con = Contractstruct({
            tokenAddress : tokenaddress,
            pairAddress : address(0),
            name : _name,
            symbol : _symbol,
            decimals : _decimals
        });
        numofContracts++;
        DeployedContracts[numofContracts] = con;
        pairAddress = createSellingPair(_owner,_admin,tokenaddress,_datas[1],_datas[2],_datas[3],_datas[4],_datas[5],_datas[6]);
        LynkpadToken(tokenaddress).transferFrom(_owner,pairAddress,_datas[5]);
        owner.transfer(address(this).balance);
    }
    function createSellingPair(address payable _owner,address _admin,address tokenAddress,uint256 _startBlock,uint256 _endBlock,uint256 _minprice,uint256 _maxprice,uint256 _totalTokenForSales,uint256 _tokenPereth) private returns(address pairAddress) {
        bytes memory bytecode = type(LynkPadIDO).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_owner,_admin,tokenAddress,_startBlock,_endBlock,_minprice,_maxprice,_totalTokenForSales,_tokenPereth));
        assembly {
          pairAddress := create2(0, add(bytecode, 32), mload(bytecode),salt)
        }
        LynkPadIDO(pairAddress).initialize(_owner,_admin,tokenAddress,_startBlock,_endBlock,_minprice,_maxprice,_totalTokenForSales,_tokenPereth);
        DeployedContracts[numofContracts].pairAddress = pairAddress;
        emit SellingPairCreated(pairAddress,_startBlock,_endBlock,_minprice,_maxprice,_totalTokenForSales,_tokenPereth);
    }
    function safeWithdraw() public {
        require(msg.sender == owner,"Permission Denied");
        owner.transfer(address(this).balance);
    }
    function changeCharges(uint256 newValue) public {
        require(msg.sender == owner,"Permission Denied");
        deployTokenCharges = newValue;
    }
    function safeWithdrawToken(address tokenAddress) public {
        require(msg.sender == owner,"Permission Denied");
        TRC20 receivedToken = TRC20(tokenAddress);
        receivedToken.transfer(owner,receivedToken.balanceOf(address(this)));
    }
}