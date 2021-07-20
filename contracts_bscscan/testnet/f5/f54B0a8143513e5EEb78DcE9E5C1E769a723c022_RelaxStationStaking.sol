/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity >=0.7.0;


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

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
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

        
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract RelaxStationToken is ERC20, Ownable {

  using SafeMath for uint256;

  address constant public INITIAL_SUPPLY_ADDRESS = address(0xd81EcEeee7943b063FD21F80aF2ae905AD946da1);

  uint256 public POSSIBLE_SUPPLY = 10**9;
  uint256 public possibleSupply;
  uint256 public maxSupply;

  mapping(address => uint256) minters;

  constructor() ERC20("Relax Station Token", "RST") {
    possibleSupply = POSSIBLE_SUPPLY.mul(10 ** uint256(decimals()));
    uint256 initialSupply = possibleSupply.mul(10).div(100); 

    _mint(msg.sender, initialSupply);
    maxSupply = initialSupply;
  }

  function addMinter(address _minter) public onlyOwner {
    require(minters[_minter] == 0, "Minter already added");

    minters[_minter] = block.timestamp;
  }

  modifier onlyMinter() {
    require(minters[_msgSender()] > 0 && Address.isContract(_msgSender()), "Caller could be only minter contract");
    _;
  }

  function mint(address _receiver, uint256 _amount) external onlyMinter {
    if (maxSupply >= possibleSupply) {
      return;
    }

    uint256 amount = _amount;
    if (maxSupply.add(amount) > possibleSupply) {
      amount = possibleSupply.sub(maxSupply);
    }

    maxSupply = maxSupply.add(amount);

    _mint(_receiver, amount);
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

}

contract RelaxStationStaking is Ownable {

    using SafeMath for uint256;

    uint256 constant public TIME_STEP = 1 days;

    address public tokenContractAddress;
    address public flipTokenContractAddress;

    struct Stake {
      uint256 amount;
      uint256 checkpoint;
      uint256 accumulatedReward;
      uint256 withdrawnReward;
    }
    mapping (address => Stake) public stakes;
    uint256 public totalStake;

    uint256 public MULTIPLIER = 1;

    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event TokensRewardWithdrawn(address indexed user, uint256 reward);

    

    function setTokenContractAddress(address _tokenContractAddress, address _flipTokenContractAddress) external onlyOwner {
      require(tokenContractAddress == address(0x0), "Token contract already configured");
      require(Address.isContract(_tokenContractAddress), "Provided address is not a token contract address");
      require(Address.isContract(_flipTokenContractAddress), "Provided address is not a flip token contract address");

      tokenContractAddress = _tokenContractAddress;
      flipTokenContractAddress = _flipTokenContractAddress;
    }

    function updateMultiplier(uint256 multiplier) public onlyOwner {
      require(multiplier > 0 && multiplier <= 50, "Multiplier is out of range");

      MULTIPLIER = multiplier;
    }

    function stake(uint256 _amount) external returns (bool) {
      require(_amount > 0, "Invalid tokens amount value");
      require(Address.isContract(flipTokenContractAddress), "Provided address is not a flip token contract address");

      if (!IERC20(flipTokenContractAddress).transferFrom(msg.sender, address(this), _amount)) {
        return false;
      }

      uint256 reward = availableReward(msg.sender);
      if (reward > 0) {
        stakes[msg.sender].accumulatedReward = stakes[msg.sender].accumulatedReward.add(reward);
      }

      stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
      stakes[msg.sender].checkpoint = block.timestamp;

      totalStake = totalStake.add(_amount);

      emit Staked(msg.sender, _amount);

      return true;
    }

    function availableReward(address userAddress) public view returns (uint256) {
      return stakes[userAddress].amount
        .mul(MULTIPLIER)
        .mul(block.timestamp.sub(stakes[userAddress].checkpoint))
        .div(TIME_STEP);
    }

    function withdrawTokensReward() external {
      uint256 reward = stakes[msg.sender].accumulatedReward
        .add(availableReward(msg.sender));

      if (reward > 0) {
        
        if (Address.isContract(tokenContractAddress)) {
          stakes[msg.sender].checkpoint = block.timestamp;
          stakes[msg.sender].accumulatedReward = 0;
          stakes[msg.sender].withdrawnReward = stakes[msg.sender].withdrawnReward.add(reward);

          RelaxStationToken(tokenContractAddress).mint(msg.sender, reward);

          emit TokensRewardWithdrawn(msg.sender, reward);
        }
      }
    }

    function unstake(uint256 _amount) external {
      require(_amount > 0, "Invalid tokens amount value");
      require(_amount <= stakes[msg.sender].amount, "Not enough tokens on the stake balance");
      require(Address.isContract(flipTokenContractAddress), "Provided address is not a flip token contract address");

      uint256 reward = availableReward(msg.sender);
      if (reward > 0) {
        stakes[msg.sender].accumulatedReward = stakes[msg.sender].accumulatedReward.add(reward);
      }

      stakes[msg.sender].amount = stakes[msg.sender].amount.sub(_amount);
      stakes[msg.sender].checkpoint = block.timestamp;

      totalStake = totalStake.sub(_amount);

      require(IERC20(flipTokenContractAddress).transfer(msg.sender, _amount));

      emit Unstaked(msg.sender, _amount);
    }

    function getStakingStatistics(address userAddress) public view returns (uint256[5] memory stakingStatistics) {
      stakingStatistics[0] = availableReward(userAddress);
      stakingStatistics[1] = stakes[userAddress].accumulatedReward;
      stakingStatistics[2] = stakes[userAddress].withdrawnReward;
      stakingStatistics[3] = stakes[userAddress].amount; 
      stakingStatistics[4] = stakes[userAddress].amount.mul(MULTIPLIER); 
    }

}