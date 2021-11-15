// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./libs/fota/TokenAuth.sol";

contract FOTAToken is IBEP20, TokenAuth {

  string public constant name = "Fight Of The Ages"; // TODO
  string public constant symbol = "FOTA";
  uint public constant decimals = 18;
  uint public constant gamingAllocation = 385e24;
  uint public constant privateSaleAllocation = 35e24;
  uint public constant ido1stAllocation = 28e24;
  uint public constant ido2ndAllocation = 35e24;
  uint public constant marketingAllocation = 35e24;
  uint public constant liquidityPoolAllocation = 63e24;
  uint public constant founderTeamAllocation = 84e24;
  uint public constant advisorAllocation = 35e24;
  uint public constant maxSupply = 700e24;
//  uint public constant blockInOneMonth = 864000; // 30 * 24 * 60 * 20
  uint public constant blockInOneMonth = 200; // 10 minutes
  uint public totalSupply;
  bool public paused;
  uint public lastReleaseMarketingBlock;
  uint public lastReleaseLiquidityPoolBlock;
  uint8 public idoReleaseCounter;
  mapping (address => uint) public lastReleaseAdvisorBlocks;
  mapping (address => uint) public lastReleaseFounderBlocks;

  uint private startBlock;
  uint private gamingReleased;

  bool releasePrivateSale;
  bool releaseIDO;
  bool releaseLiquidityPool;

  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;
  mapping (address => bool) lock;

  constructor(address _liquidityPoolAddress) TokenAuth(msg.sender, _liquidityPoolAddress) {
    startBlock = block.number;
    lastReleaseMarketingBlock = block.number;
    lastReleaseLiquidityPoolBlock = block.number;
    _mint(_liquidityPoolAddress, liquidityPoolAllocation * 20 / 100);
  }

  function releaseGameAllocation(address _gamerAddress, uint _amount) external onlyGameContract {
    require(gamingReleased + _amount <= gamingAllocation, "Max gaming allocation had released");
    _mint(_gamerAddress, _amount);
    gamingReleased = gamingReleased + _amount;
  }

  function releasePrivateSaleAllocation(address _contract) external onlyOwner {
    require(!releasePrivateSale, "Private sale Allocation had released");
    releasePrivateSale = true;
    _mint(_contract, privateSaleAllocation);
  }

  function releaseIDOAllocation(address _address) external onlyOwner {
    require(!releaseIDO, "IDO Allocation had released");
    if (idoReleaseCounter == 0) {
      idoReleaseCounter++;
      _mint(_address, ido1stAllocation);
    } else {
      releaseIDO = true;
      _mint(_address, ido2ndAllocation);
    }
  }

  function releaseMarketing() external onlyMarketingAddress {
    uint maxBlockNumber = startBlock + blockInOneMonth * 12;
    require(maxBlockNumber > lastReleaseMarketingBlock, "Marketing allocation had released");
    uint blockPass;
    if (block.number < maxBlockNumber) {
      blockPass = block.number - lastReleaseMarketingBlock;
	    lastReleaseMarketingBlock = block.number;
    } else {
      blockPass = maxBlockNumber - lastReleaseMarketingBlock;
	    lastReleaseMarketingBlock = maxBlockNumber;
    }
    uint releaseAmount = marketingAllocation * blockPass / (blockInOneMonth * 12);
    _mint(msg.sender, releaseAmount);
  }

  function releaseLiquidityPoolAllocation() external onlyLiquidityPoolAddress {
    uint maxBlockNumber = startBlock + blockInOneMonth * 6;
    require(maxBlockNumber > lastReleaseLiquidityPoolBlock, "Liquidity pool allocation had released");
    uint blockPass;
    if (block.number < maxBlockNumber) {
      blockPass = block.number - lastReleaseLiquidityPoolBlock;
      lastReleaseLiquidityPoolBlock = block.number;
    } else {
      blockPass = maxBlockNumber - lastReleaseLiquidityPoolBlock;
      lastReleaseLiquidityPoolBlock = maxBlockNumber;
    }
    uint releaseAmount = liquidityPoolAllocation * 80 / 100 * blockPass / (blockInOneMonth * 6);
    _mint(msg.sender, releaseAmount);
  }

  function releaseFounderAllocation() external onlyFounderAddress {
    require(block.number > startBlock + blockInOneMonth * 12, "Please wait more time");
    uint maxBlockNumber = startBlock + blockInOneMonth * 24;
    require(maxBlockNumber > lastReleaseFounderBlocks[msg.sender], "Founder allocation had released");
    uint blockPass;
    if (block.number < maxBlockNumber) {
      blockPass = block.number - lastReleaseFounderBlocks[msg.sender];
      lastReleaseFounderBlocks[msg.sender] = block.number;
    } else {
      blockPass = maxBlockNumber - lastReleaseFounderBlocks[msg.sender];
      lastReleaseFounderBlocks[msg.sender] = maxBlockNumber;
    }
    uint releaseAmount = founderAddresses[msg.sender] * blockPass / (blockInOneMonth * 12);
    _mint(msg.sender, releaseAmount);
  }

  function releaseAdvisorAllocation() external onlyAdvisorAddress {
    require(block.number > startBlock + blockInOneMonth * 6, "Please wait more time");
    uint maxBlockNumber = startBlock + blockInOneMonth * 18;
    require(maxBlockNumber > lastReleaseAdvisorBlocks[msg.sender], "Advisor allocation had released");
    uint blockPass;
    if (block.number < maxBlockNumber) {
      blockPass = block.number - lastReleaseAdvisorBlocks[msg.sender];
      lastReleaseAdvisorBlocks[msg.sender] = block.number;
    } else {
      blockPass = maxBlockNumber - lastReleaseAdvisorBlocks[msg.sender];
      lastReleaseAdvisorBlocks[msg.sender] = maxBlockNumber;
    }
    uint releaseAmount = advisorAddresses[msg.sender] * blockPass / (blockInOneMonth * 12);
    _mint(msg.sender, releaseAmount);
  }

  function balanceOf(address _owner) override external view returns (uint) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender) override external view returns (uint) {
    return _allowed[_owner][_spender];
  }

  function transfer(address _to, uint _value) override external returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) override external returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) override external returns (bool) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, _allowed[_from][msg.sender] - _value);
    return true;
  }

  function increaseAllowance(address _spender, uint _addedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] + _addedValue);
    return true;
  }

  function decreaseAllowance(address _spender, uint _subtractedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] - _subtractedValue);
    return true;
  }

  function burn(uint _amount) external {
    _balances[msg.sender] = _balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(msg.sender, address(0), _amount);
  }

  function updatePauseStatus(bool _paused) onlyOwner external {
    paused = _paused;
  }

  function updateLockStatus(address _address, bool locked) onlyOwner external {
    lock[_address] = locked;
  }

  function checkLockStatus(address _address) external view returns (bool) {
    return lock[_address];
  }

  function setFounderAddress(address _address, uint _allocation) public override {
  	super.setFounderAddress(_address, _allocation);
    lastReleaseFounderBlocks[_address] = startBlock + blockInOneMonth * 12;
  }

  function updateFounderAddress(address _oldAddress, address _newAddress) public override {
    super.updateFounderAddress(_oldAddress, _newAddress);
    lastReleaseFounderBlocks[_newAddress] = lastReleaseFounderBlocks[_oldAddress];
    delete lastReleaseFounderBlocks[_oldAddress];
  }

  function setAdvisorAddress(address _address, uint _allocation) public override {
  	super.setAdvisorAddress(_address, _allocation);
    lastReleaseAdvisorBlocks[_address] = startBlock + blockInOneMonth * 6;
  }

  function updateAdvisorAddress(address _oldAddress, address _newAddress) public override {
    super.updateAdvisorAddress(_oldAddress, _newAddress);
    lastReleaseAdvisorBlocks[_newAddress] = lastReleaseAdvisorBlocks[_oldAddress];
    delete lastReleaseAdvisorBlocks[_oldAddress];
  }

  function _transfer(address _from, address _to, uint _value) private {
    require(!lock[_from] || !paused, "You can not do this at the moment");
    _balances[_from] = _balances[_from] - _value;
    _balances[_to] = _balances[_to] + _value;
    if (_to == address(0)) {
      totalSupply = totalSupply - _value;
    }
    emit Transfer(_from, _to, _value);
  }

  function _approve(address _owner, address _spender, uint _value) private {
    require(_spender != address(0));
    require(_owner != address(0));

    _allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }

  function _mint(address _owner, uint _amount) private {
    require(!lock[_owner] || !paused, "You can not do this at the moment");
    require(totalSupply + _amount <= maxSupply, "Amount invalid");
    _balances[_owner] = _balances[_owner] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _owner, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

contract TokenAuth is Context {

  address internal owner;
  mapping (address => bool) public gameAddresses;
  mapping (address => uint) public advisorAddresses;
  mapping (address => uint) public founderAddresses;
  address marketingAddress;
  address liquidityPoolAddress;

  uint constant maxAdvisorAllocation = 35e24;
  uint constant maxFounderTeamAllocation = 84e24;
  uint advisorAllocated;
  uint founderAllocated;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _owner,
    address _liquidityPoolAddress
  ) {
    owner = _owner;
    liquidityPoolAddress = _liquidityPoolAddress;
  }

  modifier onlyOwner() {
    require(isOwner(), "onlyOwner");
    _;
  }

  modifier onlyGameContract() {
    require(isOwner() || isGameContract(), "TokenAuth: invalid caller");
    _;
  }

  modifier onlyMarketingAddress() {
    require(_msgSender() == marketingAddress, "TokenAuth: invalid caller");
    _;
  }

  modifier onlyLiquidityPoolAddress() {
    require(_msgSender() == liquidityPoolAddress, "TokenAuth: invalid caller");
    _;
  }

  modifier onlyAdvisorAddress() {
    require(advisorAddresses[_msgSender()] > 0, "TokenAuth: invalid caller");
    _;
  }

  modifier onlyFounderAddress() {
    require(founderAddresses[_msgSender()] > 0, "TokenAuth: invalid caller");
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "TokenAuth: invalid new owner");
    owner = _newOwner;
    emit OwnershipTransferred(_msgSender(), _newOwner);
  }

  function setGameAddress(address _gameAddress, bool _status) public onlyOwner {
    require(_gameAddress != address(0), "TokenAuth: game address is the zero address");
    gameAddresses[_gameAddress] = _status;
  }

  function setMarketingAddress(address _address) external onlyOwner {
    require(_address != address(0), "TokenAuth: marketing address is the zero address");
    marketingAddress = _address;
  }

  function setLiquidityPoolAddress(address _address) external onlyOwner {
    require(_address != address(0), "TokenAuth: liquidity address is the zero address");
    liquidityPoolAddress = _address;
  }

  function setFounderAddress(address _address, uint _allocation) public virtual onlyOwner {
    require(_address != address(0), "TokenAuth: founder address is the zero address");
    require(founderAllocated + _allocation <= maxFounderTeamAllocation, "Invalid amount");
    founderAddresses[_address] = _allocation;
    founderAllocated = founderAllocated + _allocation;
  }

  function updateFounderAddress(address _oldAddress, address _newAddress) public virtual onlyOwner {
    require(_oldAddress != address(0), "TokenAuth: founder address is the zero address");
    founderAddresses[_newAddress] = founderAddresses[_oldAddress];
    delete founderAddresses[_oldAddress];
  }

  function setAdvisorAddress(address _address, uint _allocation) public virtual onlyOwner {
    require(_address != address(0), "TokenAuth: advisor address is the zero address");
    require(advisorAllocated + _allocation <= maxAdvisorAllocation, "Invalid amount");
    advisorAddresses[_address] = _allocation;
    advisorAllocated = advisorAllocated + _allocation;
  }

  function updateAdvisorAddress(address _oldAddress, address _newAddress) public virtual onlyOwner {
    require(_oldAddress != address(0), "TokenAuth: advisor address is the zero address");
    advisorAddresses[_newAddress] = advisorAddresses[_oldAddress];
    delete advisorAddresses[_oldAddress];
  }

  function isOwner() public view returns (bool) {
    return _msgSender() == owner;
  }

  function isGameContract() public view returns (bool) {
    return gameAddresses[_msgSender()];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
abstract contract IBEP20 {
    function transfer(address to, uint256 value) external virtual returns (bool);

    function approve(address spender, uint256 value) external virtual returns (bool);

    function transferFrom(address from, address to, uint256 value) external virtual returns (bool);

    function balanceOf(address who) external virtual view returns (uint256);

    function allowance(address owner, address spender) external virtual view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

