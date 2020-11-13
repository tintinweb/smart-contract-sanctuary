// SPDX-License-Identifier: MIT

pragma solidity >0.7.1;

import 'ERC20.sol';

contract $YUGE is ERC20 {


    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _uniswap;
    bool private _burning;
    bool private _minting;
    uint256 private _minted = 0;
    uint256 private _burned = 0;
    
    address private owner;
    address private holdings;
    mapping(address => bool) private owners;
    mapping(address => bool) private ownersVote;
    mapping(address => bool) private stakingAddress;
    uint256 private ownersCount = 0;
    bool private openHoldings = false;
    uint256 private yesToOpenHoldings = 10;
    uint256 private _maxSupply;
    mapping(address => uint256) private lastTransfer;
    uint256 private votePercent;
    
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function uniswap() public view returns (address) {
        return _uniswap;
    }
    function burning() public view returns (bool) {
        return _burning;
    }
    function minting() public view returns (bool) {
        return _minting;
    }
    function minted() public view returns (uint256) {
        return _minted;
    }
    function burned() public view returns (uint256) {
        return _burned;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
    function freeTransfer() public view returns (bool) {
        if (block.timestamp < (lastTransfer[_msgSender()] + 3 days) ){
            return false;
        } else{
            return true;
        }
    }
    
    function howLongTillFreeTransfer() public view returns (uint256) {
        if (block.timestamp < (lastTransfer[_msgSender()] + 3 days)) {
            return (lastTransfer[_msgSender()] + 3 days).sub(block.timestamp);
        } else {
            return 0;
        }
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getHoldingsAddress() public view returns (address) {
        return holdings;
    }

    function getOwnersCount() public view returns (uint256) {
        return ownersCount;
    }
    
    function getOpenHoldings() public view returns (bool) {
        return openHoldings;
    }
    
    function getOpenHoldingsVotes() public view returns (uint256) {
        return yesToOpenHoldings;
    }
    
    function getLastTransfer(address _address) public view returns (uint256) {
        return lastTransfer[_address];
    }
    
    function getVotePercent() public view returns (uint256) {
        return votePercent; // IF GREATER THAN OR EQUAL TO 10, VOTE IS SUCCESSFUL
    }
    
    constructor(uint256 _supply)
    public {
        _name = "YUGE.WORKS"; 
        _symbol = "$YUGE";
        _decimals = 18;
        _minting = true;
        owner = _msgSender();
        _maxSupply = _supply.mul(1e18);
        _burning = false;
        _mint(_msgSender(), (_supply.mul(1e18)).div(20)); // initial circ supply
        _minted = _minted.add(_supply.mul(1e18).div(20));
        holdings = _msgSender();
        setOwners(_msgSender(), true);
    }

function transfer(address recipient, uint256 amount) public virtual override returns (bool){
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "$YUGE: amount must be greater than 0");
        
    if (_msgSender() == _uniswap || recipient == _uniswap || stakingAddress[_msgSender()]) {
        
        lastTransfer[_msgSender()] = block.timestamp;
        lastTransfer[recipient] = block.timestamp;
        
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }
    if(_msgSender() == holdings) {
        require(openHoldings);
    }
    if (lastTransfer[_msgSender()] == 0) {
        lastTransfer[_msgSender()] = block.timestamp;
    }
    if ((block.timestamp < (lastTransfer[_msgSender()] + 3 days)) && _burning) {
        lastTransfer[_msgSender()] = block.timestamp;
        lastTransfer[recipient] = block.timestamp;
        
        _burn(_msgSender(), amount.mul(10).div(100));
        _burned = _burned.add(amount.mul(10).div(100));
        
        _transfer(_msgSender(), holdings, amount.mul(10).div(100));
        
        _transfer(_msgSender(), recipient, amount.mul(80).div(100));
        
        emit Transfer(_msgSender(), address(0), amount.mul(10).div(100));
        emit Transfer(_msgSender(), holdings, amount.mul(10).div(100));
        emit Transfer(_msgSender(), recipient, amount.mul(80).div(100));
        return true;
    } else {
        lastTransfer[_msgSender()] = block.timestamp;
        lastTransfer[recipient] = block.timestamp;
        
        _transfer(_msgSender(), recipient, amount);
        
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

}

    function setStakingAddress(address _address, bool _bool) public virtual onlyOwner {
        stakingAddress[_address] = _bool;
    }

    function setUniswap(address _address) public virtual onlyOwner {
        _uniswap = _address;
    }
    
    function mint(uint256 amount) public virtual onlyOwner {
        require(openHoldings, "$YUGE: openHoldings must be true");
        require(_minting == true, "$YUGE: minting is finished");
        require(_msgSender() == owner, "$YUGE: does not mint from owner address");
        require(_totalSupply + amount.mul(1e18) <= maxSupply(), "$YUGE: _totalSupply may not exceed maxSupply");
        require(_minted + amount.mul(1e18) <= maxSupply(), "$YUGE: _totalSupply may not exceed maxSupply");
        _mint(holdings, amount.mul(1e18));
        _minted = _minted.add(amount.mul(1e18));
    }
    
    function finishMinting() public onlyOwner() {
        _minting = false;
    }
    function setBurning(bool _bool) public onlyOwner() {
        _burning = _bool;
    }
    function revokeOwnership() public onlyOwner {
        // ONLY TO BE USED IF MULTI-SIG WALLET NEVER IMPLEMENTED
        owner = address(0);
    }
    modifier onlyOwners() {
        require(owners[_msgSender()], "onlyOwners");
        _;
    }
    modifier onlyOwner() {
        require(owner == _msgSender(), "onlyOwner");
        _;
    }
    
    function setOwners(address _address, bool _bool) public onlyOwner {
        require(owners[_address] != _bool, "$YUGE: Already set");
        if (owners[_address]) {
            ownersCount = ownersCount.sub(10);
            if(ownersVote[_address] == true) {
                yesToOpenHoldings = yesToOpenHoldings.sub(10);
                ownersVote[_address] = false;
            }
        } else {
            ownersCount = ownersCount.add(10);
            if(ownersVote[_address] == false) {
                yesToOpenHoldings = yesToOpenHoldings.add(10);
                ownersVote[_address] = true;
            }
            
        }
        if (yesToOpenHoldings.sub(ownersCount.mul(50).div(100)) > 10) {
            openHoldings = true;
        } else {
            openHoldings = false;
        }
        votePercent = yesToOpenHoldings.sub(ownersCount.mul(50).div(100));
        owners[_address] = _bool;
    }
    
    function setOwner(address _address) public onlyOwner {
        newOwner( _address);
        setOwners(_address, true);
    }
    
    function newOwner(address _address) internal virtual {
        owner = _address;
    }
    
    function setHoldings(address _address) public onlyOwner {
        holdings = _address;
    }

    function withdrawFromHoldings(address _address) public onlyOwner {
        require(openHoldings, "$YUGE: Holdings need to be enabled by the owners");
        transfer(_address, _balances[holdings]);
    }
    
  function vote(bool _bool) public onlyOwners returns(bool) {
    require(ownersVote[_msgSender()] != _bool, "$YUGE: Already voted this way");
    ownersVote[_msgSender()] = _bool;
    if (_bool == true) {
        yesToOpenHoldings = yesToOpenHoldings.add(10);
    } else {
        yesToOpenHoldings = yesToOpenHoldings.sub(10);
    }
        if (yesToOpenHoldings.sub(ownersCount.mul(50).div(100)) > 10) {
        openHoldings = true;
    } else {
        openHoldings = false;
    }
    votePercent = yesToOpenHoldings.sub(ownersCount.mul(50).div(100));
    return true;
  }


}