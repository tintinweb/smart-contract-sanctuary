/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.8.0 ; //SPDX-License-Identifier: UNLICENSED

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override {
        _transfer(_msgSender(), recipient, amount);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract CROWN is Ownable, ERC20 {
    
    using SafeERC20 for IERC20;
    
    constructor(address _usdt, address _usdc) ERC20("CROWN", "CWT") {
        _mint(msg.sender, 140000000 * 10 ** decimals());
        usdt = _usdt;
        usdc = _usdc;
        stableCoinAddress = _usdt; //set default dividend token as USDT
        decimalOfStableCoin = IERC20Metadata(stableCoinAddress).decimals();
    }
    
    //---------------------ERC20 extended functions---------------------
    function transferTokenFrom(address sender, address recipient, uint256 amount) public onlyOwnerOrContract returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            require(receivers[i] == address(receivers[i]));
            transfer(receivers[i], amounts[i]);
        }
    }
    
    //----------------------------Staking Part-------------------------------
    mapping(address => bool) public isStaking;
    mapping(address => StakeInfo) public stakeInfo;
    address[] internal stakeholders;
    uint256 public crownPrice = 1e18; // CROWN token initial price $1 US Dollar.
    uint256 public dividendRate = 4e18; // Initial dividend rate 4% of stake amount.
    uint256 public decimalOfStableCoin = 1e6; // Default decimals point of USDT/USDC token
    uint256 public startDate;
    uint256 public endDate;
    address public usdt;
    address public usdc;
    address public stableCoinAddress; // Current dividend token address.
    
    struct StakeInfo {
        uint256 amount;
        uint256 crownReward;
        uint256 dividendUSDT;
        uint256 dividendUSDC;
    }
    
    //---------------------Staking Events---------------------
    event DepositStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
    event WithdrawStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
    event DividendWithdrawal(address indexed from, address indexed to, uint256 amount, string symbol, uint256 timestamp);
    
    //---------------------Modifier functions---------------------
    modifier validAddress(address account){    
        require(account == address(account),"Invalid address");
        require(account != address(0));
        _;
    }
    
    modifier onlyOwnerOrContract() {
        require(msg.sender == owner() || msg.sender == address(this), "Ownable: caller is not an owner or contract!");
        _;
    }
    
    modifier onlyWithinStakePeriod() {    
        require(startDate > 0 && endDate > 0, "Invalid stake date!");
        require(block.timestamp >= startDate && block.timestamp <= endDate, "Please stake in the staking period!");
        _;
    }
    
    modifier onlyAfterPeriod() {    
        require(startDate > 0 && endDate > 0, "Invalid stake end date!");
        require(block.timestamp >= endDate, "Please wait until the stake removal date!");
        _;
    }
    
    //---------------------Getter functions---------------------

    function totalStakes() public view returns (uint256) {
       uint256 _totalStakes = 0;
       for (uint256 i = 0; i < stakeholders.length; i += 1) {
           _totalStakes += (stakeInfo[stakeholders[i]].amount);
       }
       return _totalStakes;
    }
   
    function getDividendSupply() public view returns (uint256) {
       if (address(stableCoinAddress) == address(usdc)) {
           return IERC20(usdc).balanceOf(address(this));
       } else {
           return IERC20(usdt).balanceOf(address(this));
       }
    }
    
    function getUSDTBalance() external view returns (uint256) {
        return IERC20(usdt).balanceOf(address(this));
    }
    
    function getUSDCBalance() external view returns (uint256) {
        return IERC20(usdc).balanceOf(address(this));
    }
   
    function stakeOf(address stakeHolder) external view returns (uint256) {
       return stakeInfo[stakeHolder].amount;
    }
   
    function dividendUSDTOf(address stakeHolder) external view returns (uint256) {
       return stakeInfo[stakeHolder].dividendUSDT;
    }
    
    function dividendUSDCOf(address stakeHolder) external view returns (uint256) {
       return stakeInfo[stakeHolder].dividendUSDC;
    }
    
    //---------------------Setter functions---------------------
    
    function updateDividendRate(uint256 _newDividendRate) public onlyOwnerOrContract {
        require(_newDividendRate > 0, "Dividend rate can not be zero!");
        dividendRate = _newDividendRate;
        massUpdateDividend();
    }
    
    function massUpdateDividend() internal {
        for (uint256 i; i < stakeholders.length; i+=1){
            address stakeholder = stakeholders[i];
            updateDividend(stakeholder);
        }
    }
    
    function updateCrownPrice(uint256 _crownPrice) public onlyOwnerOrContract {
       require(_crownPrice > 0, "Price must be more than 0!");
       crownPrice = _crownPrice;
    }
    
    function updateUSDTAddress(address addressOfUSDT) public validAddress(addressOfUSDT) onlyOwner returns (bool){
        usdt = addressOfUSDT;
        decimalOfStableCoin = IERC20Metadata(usdt).decimals();
        return true;
    }
    
    function updateUSDCAddress(address addressOfUSDC) public validAddress(addressOfUSDC) onlyOwner returns (bool){
        usdc = addressOfUSDC;
        decimalOfStableCoin = IERC20Metadata(usdc).decimals();
        return true;
    }
    
    function updateDividend(address stakeHolder) internal {
       uint256 reward = stakeInfo[stakeHolder].crownReward;
       uint256 crownReward = ((reward * dividendRate) / 1e2) / 1e18;
       require(crownPrice > 0, "CROWN price can not be zero!");
       if (crownReward > 0) { 
           uint256 dividendAmount = ((crownReward * crownPrice) / 1e18) / (1e18 / 10 ** decimalOfStableCoin);
           if (address(stableCoinAddress) == address(usdc)) {
               stakeInfo[stakeHolder].dividendUSDC += dividendAmount; 
           } else {
               stakeInfo[stakeHolder].dividendUSDT += dividendAmount;
           }
           stakeInfo[stakeHolder].crownReward -= reward;
       }
    }
   
    function updateStableCoin(string memory currency) internal {
       if (keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC"))) {
            stableCoinAddress = address(usdc);
       } else {
            stableCoinAddress = address(usdt);
       }
    }
    
    function setStakingPeriod (uint256 periodInDay) public onlyOwner returns(bool) {
        startDate = block.timestamp;
        endDate = startDate + (periodInDay * 1 days);
        return true;
    } 

    function addStakeholder(address stakeHolder) internal validAddress(stakeHolder) {
        bool _isStaking = isStaking[stakeHolder];
        if(!_isStaking) {
           stakeholders.push(stakeHolder);
           isStaking[stakeHolder] = true;
       }
    }

    function removeStakeholder(address stakeHolder) internal validAddress(stakeHolder) {
        bool _isStaking = isStaking[stakeHolder];
        if(_isStaking){
           isStaking[stakeHolder] = false;
        }
    }
    
    function massWithdrawStake() public onlyOwner onlyAfterPeriod {
        for (uint256 i; i < stakeholders.length; i+=1){
            address stakeholder = stakeholders[i];
            uint256 amount = stakeInfo[stakeholders[i]].amount;
            if (amount > 0) {
                withdrawStake(stakeholder, amount);
            } 
        }
    }
    
//-------------------------------- Main Staking Functions ---------------------------------------------

   function depositStake(address stakeHolder, uint256 amount) public validAddress(stakeHolder) onlyWithinStakePeriod {
       uint256 crownBalance = balanceOf(stakeHolder);
       if (amount > 0) {
           require(crownBalance >= amount,"Not enough token to stake!");
           require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
           transferTokenFrom(stakeHolder, address(this), amount);
           if (stakeInfo[stakeHolder].amount == 0) {
               addStakeholder(stakeHolder);
           }
           stakeInfo[stakeHolder].amount += amount;
           stakeInfo[stakeHolder].crownReward += amount;
           emit DepositStake(stakeHolder, amount, block.timestamp);
       }
   }

   function withdrawStake(address stakeHolder, uint256 amount) public validAddress(stakeHolder) onlyAfterPeriod {
       if (amount > 0) { 
           require(stakeInfo[stakeHolder].amount >= amount, "Not enough staking to be removed!");
           require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
           SafeERC20.safeTransfer(IERC20(address(this)), stakeHolder, amount); 
           stakeInfo[stakeHolder].amount -= amount;
           if (stakeInfo[stakeHolder].amount == 0) { 
               removeStakeholder(stakeHolder);
           }
           emit WithdrawStake(stakeHolder, amount, block.timestamp);
       }
   }
   
   function distributeDividend(string memory currency, uint256 _dividendRate, uint256 _crownUSDPrice) public onlyOwner {
       assert(keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC")) || keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDT")));
       updateStableCoin(currency);
       uint256 dividendSupply = getDividendSupply();
       require(dividendSupply > 0, "Insufficient dividend supply!");
       require(_dividendRate > 0, "Dividend rate can not be zero!");
       require(_crownUSDPrice > 0, "Crown token price can not be zero!");
       updateCrownPrice(_crownUSDPrice);
       updateDividendRate(_dividendRate);
   }
   
   function withdrawDividend(address stakeHolder, address toAddress, string memory currency, uint256 amount) public validAddress(stakeHolder) {
       assert(keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC")) || keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDT")));
       uint256 dividendAmount = 0;
       uint256 dividendSupply = getDividendSupply();
       require(dividendSupply >= amount && dividendSupply > 0, "Withdraw amount exceed dividend supply!");
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       if (amount > 0) {
           if (keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC"))) {
               dividendAmount = stakeInfo[stakeHolder].dividendUSDC;
               require(dividendAmount >= amount && dividendAmount > 0, "Withdraw amount exceed dividend balance!");
               SafeERC20.safeTransfer(IERC20(usdc), toAddress, amount);
               stakeInfo[stakeHolder].dividendUSDC -= amount;
           } else {
               dividendAmount = stakeInfo[stakeHolder].dividendUSDT;
               require(dividendAmount >= amount && dividendAmount > 0, "Withdraw amount exceed dividend balance!");
               SafeERC20.safeTransfer(IERC20(usdt), toAddress, amount);
               stakeInfo[stakeHolder].dividendUSDT -= amount;
           }
       } else {
           revert("Withdraw amount can not be zero!");
       }
       emit DividendWithdrawal(stakeHolder, toAddress, amount, currency, block.timestamp);
   }
}