/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract FIXGold is IERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isFirstSale;

    uint256 public constant SECONDS_PER_WEEK = 604800;   // 7 * 24 * 60 * 60
    uint256 private constant MSK_2021_09_04_10_00 = 1630738800;

    uint256 private constant PERCENTAGE_MULTIPLICATOR = 1e4; // 10000

    uint8 private constant DEFAULT_DECIMALS = 6;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _firstUpdate;
    uint256 private _lastUpdate;

    uint256 private _growthRate;
    uint256 private _growthRate_after;

    uint256 private _price;

    uint256 private _presaleStart;
    uint256 private _presaleEnd;

    bool private _isStarted;

    uint256 [] _zeros;

    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount, uint256 price);
    event TokensSold(address indexed seller, uint256 amount, uint256 USDT, uint256 price);
    event PriceUpdated(uint price);


    constructor (uint256 _ownerSupply, address marketing)  {
        _decimals = 18;
        _name = "ProFIXone Gold Token";
        _symbol = "FixGold";
        _totalSupply = 250_000_000 * uint(10) ** _decimals;
        require (_ownerSupply <= _totalSupply, "Owner supply must be lower than total supply");
        _price = 1_000_000; //1_000_000
        _growthRate = 72; // 1%
        _balances[address(this)] = _totalSupply.sub(_ownerSupply).sub(2_000_000);
        _balances[marketing] = _balances[marketing].add(2_000_000);
        _balances[owner()] = _balances[owner()].add(_ownerSupply);
        emit Transfer(address(0), address(this), _totalSupply.sub(_ownerSupply));
        emit Transfer(address(0), owner(), _ownerSupply);
    }


    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public view override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) onlyOwner public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) onlyOwner public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (msg.sender != owner()) {
            require(recipient == owner(), "Tokens can be sent only to owner address.");
        }
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    
    function calculatePrice() public view returns (uint256) {
        if (_isStarted == false || _firstUpdate > block.timestamp || block.timestamp <= MSK_2021_09_04_10_00) {
            return _price;
        }
        
        uint256 i;
        uint256 skip=0;
        uint256 newPrice = _price;

        if (block.timestamp > _lastUpdate) {
            i = uint256((_lastUpdate.sub(_firstUpdate)).div(SECONDS_PER_WEEK).add(uint256(1)));
            for (uint8 x = 0; x < _zeros.length; x++) {
                if (_zeros[x] <= i) {
                    skip = skip.add(uint256(1));
                }
            }
            for (uint256 x = 0; x < i.sub(skip); x++) {
                newPrice = newPrice.mul(PERCENTAGE_MULTIPLICATOR.add(_growthRate)).div(PERCENTAGE_MULTIPLICATOR);
            }
            if (_growthRate_after > 0) {
                i = uint256((block.timestamp.sub(_lastUpdate)).div(SECONDS_PER_WEEK));
                for (uint256 x = 0; x < i; x++) {
                    newPrice = newPrice.mul(PERCENTAGE_MULTIPLICATOR.add(_growthRate_after)).div(PERCENTAGE_MULTIPLICATOR);
                }
            }
        } else {
            i = uint256((block.timestamp.sub(MSK_2021_09_04_10_00)).div(SECONDS_PER_WEEK)).add(uint256(1));
            for (uint8 x = 0; x < _zeros.length; x++) {
                if (_zeros[x] <= i) {
                    skip = skip.add(uint256(1));
                }
            }
            for (uint256 x = 0; x < i.sub(skip); x++) {
                newPrice = newPrice.mul(PERCENTAGE_MULTIPLICATOR.add(_growthRate)).div(PERCENTAGE_MULTIPLICATOR);
            }

        }
        return newPrice;
    }


  

    function currentPrice() public view returns (uint256) {
        return calculatePrice();
    }

    function growthRate() public view returns (uint256) {
        return _growthRate_after;
    }


    function isStarted() public view returns (bool) {
        return _isStarted;
    }

    function presaleStart() public view returns (uint256) {
        return _presaleStart;
    }

    function presaleEnd() public view returns (uint256) {
        return _presaleEnd;
    }


    function startContract(uint256 firstUpdate, uint256 lastUpdate, uint256 [] memory zeros) external onlyOwner {
        
    
        require (_isStarted == false, "Contract is already started.");
        require (firstUpdate >= block.timestamp, "First price update time must be later than today");
        require (lastUpdate >= block.timestamp, "Last price update time must be later than today");
        require (lastUpdate > firstUpdate, "Last price update time must be later than first update");
        _firstUpdate = firstUpdate;
        _lastUpdate = lastUpdate;
        _isStarted = true;
        for (uint8 x = 0; x < zeros.length; x++) {
            _zeros.push(zeros[x]);
        }

    }

    function setPresaleStart(uint256 new_date) external onlyOwner {
        require (_isStarted == true, "Contract is not started.");
        require(new_date >= block.timestamp, "Start time must be later, than now");
        require(new_date > _presaleStart, "New start time must be higher then previous.");
        _presaleStart = new_date;
    }

    function setPresaleEnd(uint256 new_date) external onlyOwner {
        require (_isStarted == true, "Contract is not started.");
        require(new_date >= block.timestamp, "End time must be later, than now");
        require(new_date > _presaleEnd, "New end time must be higher then previous.");
        require(new_date > _presaleStart, "New end time must be higher then start date.");
        _presaleEnd = new_date;
    }


    function setGrowthRate(uint256 _newGrowthRate) external onlyOwner {
        require (_isStarted == true, "Contract is not started.");
        require(block.timestamp > _lastUpdate, "Growth rate cannot be changed within 60 months");
        _growthRate_after =_newGrowthRate;
    }


    function calculateTokens(uint256 amount, uint8 coin_decimals, uint256 updatedPrice) public view returns(uint256) {
        uint256 result;
        if (coin_decimals >= DEFAULT_DECIMALS) {
            result = amount.mul(10 ** uint256(_decimals)).div(updatedPrice.mul(10 ** uint256(coin_decimals-DEFAULT_DECIMALS)));
        } else {
            result = amount.mul(10 ** uint256(_decimals)).div(updatedPrice.div(10 ** uint256(DEFAULT_DECIMALS-coin_decimals)));

        }
        if (block.timestamp >= _presaleStart && block.timestamp <= _presaleEnd) {
            if (amount >= uint256(1000).mul(10 ** uint256(coin_decimals))) {
                result.add(100 * uint(10) ** _decimals);
            }
        }

        return result;
    }


    function sendTokens(address recepient, uint256 amount, uint8 coinDecimals) external onlyOwner {
        require (_isStarted == true, "Contract is not started.");
        require (_presaleStart > 0, "Presale start not set");
        require (_presaleEnd > 0, "Presale end not set");
        require (coinDecimals > 0, "Stablecoin decimals must be grater than 0");
        require (amount > 0, "Stablecoin value cannot be zero.");
        require(recepient != address(0), "ERC20: transfer to the zero address");
        uint256 lastPrice = calculatePrice();
        
        uint FIXAmount = calculateTokens(amount, coinDecimals, lastPrice);
        require(_balances[address(this)] >= FIXAmount, "Insufficinet FIX amount left on contract");
        _balances[address(this)] = _balances[address(this)].sub(FIXAmount, "ERC20: transfer amount exceeds balance");
        _balances[recepient] = _balances[recepient].add(FIXAmount);
        emit TokensPurchased(recepient, amount, FIXAmount, lastPrice);
        emit Transfer(address(this), recepient, FIXAmount);

    }

    function sellTokens(address stablecoin, uint256 amount) external {
        require (_isStarted == true, "Contract is not started.");
        require (_presaleStart > 0, "Presale start not set");
        require (_presaleEnd > 0, "Presale end not set");
        require (amount > 0, "FIX value cannot be zero.");
        require(msg.sender != address(0), "ERC20: transfer to the zero address");
        require(stablecoin != address(0), "Stablecoin must not be zero address");
        require(stablecoin.isContract(), "Not a valid stablecoin contract address");
        uint256 coin_amount;

        IERC20 coin = IERC20(stablecoin);
        uint8 coin_decimals = coin.decimals();
        uint256 lastPrice = calculatePrice();

        require (_balances[msg.sender] >= amount, "Insufficient FIX token amount");
        if (coin_decimals >= 12) {
            coin_amount = amount.div(lastPrice).mul(10 ** uint256(coin_decimals-12));
        } else {
            coin_amount = amount.div(lastPrice).div(10 ** uint256(12 - coin_decimals));
        }

        _balances[address(this)] = _balances[address(this)].add(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(this), amount);
        emit TokensSold(msg.sender, amount, coin_amount, lastPrice);
    }

}