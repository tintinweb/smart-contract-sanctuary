/**
 *Submitted for verification at hecoinfo.com on 2022-05-11
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

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
interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals()  view external returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract FEToken is Context, IERC20,Ownable {
    using SafeMath for uint256;

    address public FEuniswapV2Pair;
    address public HBTuniswapV2Pair;
    address public USDTuniswapV2Pair;

    uint256 currentIndex;

    mapping(address => bool) private _isExcludedFromFee;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public fenHongPeriod = 6 hours;
    uint256 public transferLock = 24 hours;
    uint256 public startTime;
    uint256 public fenhongTime;
    address public fenHongAddress;
    mapping(address => bool) public _updated;
    address public USDTAddress = address(0x08235525De12B255CB133839d84DA440DF01E4F9);
    address public HBTAddress = address(0xf737C9bfA018655c60A609C4f4dCb44FC37Ce9B7);
    address public FEAddress = address(0x6F919F700Ae73889CBbBC3Ce3D68bF41aB0D3Ab6);

    mapping (address => uint256) public shareholderIndexes;
    address[] public shareholders;

    uint256 public _destroyFee = 10;
    uint256 public fenhongFee = 50;
    uint public addPriceTokenAmount = 1;


    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);



    constructor (address _sender,address _fenHongAddress,address factoryAddress) {
        _name = "FEDAO token";
        _symbol = "FEDAO";
        _decimals = 18;
        startTime = block.timestamp;
        fenhongTime = block.timestamp;
        fenHongAddress = _fenHongAddress;
            FEuniswapV2Pair = IUniswapV2Factory(factoryAddress)
            .createPair(address(this), FEAddress);
            HBTuniswapV2Pair = IUniswapV2Factory(factoryAddress)
            .createPair(address(this), HBTAddress);
            USDTuniswapV2Pair = IUniswapV2Factory(factoryAddress)
            .createPair(address(this), USDTAddress);
       
        _mint(_sender, 10000 * 10 ** _decimals);
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function decimals() public override view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        bool buyFlag = false;
        if(sender == FEuniswapV2Pair || sender == HBTuniswapV2Pair || sender == USDTuniswapV2Pair){
            buyFlag = true;
            if(amount > 5 * 10 ** 16){
                require(block.timestamp > (startTime + transferLock), "ERC20: first 24 hours transfer amount must be less than 0.05");
            }
         }
          _fenhong();
         bool isAdd = false;
         address addressPair = address(0);
         if(recipient == FEuniswapV2Pair){
             addressPair = FEuniswapV2Pair;
         }
         if(recipient == HBTuniswapV2Pair){
             addressPair = HBTuniswapV2Pair;
         }
         if(recipient == USDTuniswapV2Pair){
             addressPair = USDTuniswapV2Pair;
         }
          if(addressPair != address(0)){
              bool result1 = _isLiquidity1(addressPair);
              bool result2 = _isLiquidity2(addressPair);
              if(result1 || result2){
                  isAdd = true;
              }
          }

         if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && !isAdd && !buyFlag){

         uint256 destoryAmount =  amount.div(1000).mul(_destroyFee);
         _balances[sender] = _balances[sender].sub(destoryAmount, "ERC20: destory amount exceeds balance");
         _balances[_destroyAddress] = _balances[_destroyAddress].add(destoryAmount);
          emit Transfer(sender, _destroyAddress, destoryAmount);

          uint256 fengHongAmount = amount.div(1000).mul(fenhongFee);
          _balances[sender] = _balances[sender].sub(fengHongAmount);
          _balances[fenHongAddress] = _balances[fenHongAddress].add(fengHongAmount);
          emit Transfer(sender, fenHongAddress, fengHongAmount);

        uint256 recipientFee = 1000 - _destroyFee - fenhongFee;
        uint256 recipAmount = amount.div(1000).mul(recipientFee);
        _balances[sender] = _balances[sender].sub(recipAmount);
        _balances[recipient] = _balances[recipient].add(recipAmount);
        emit Transfer(sender, recipient, recipAmount);
        }else{
            if(isAdd){
              setShare(sender);
            }
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _isLiquidity1(address uniswapV2Pair)internal view returns(bool){
        address token1 = IUniswapV2Pair(uniswapV2Pair).token1();
        ( ,uint r1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        bool isAdd =false;
        uint bal1= IERC20(token1).balanceOf(uniswapV2Pair);
         if(token1 != address(this) && bal1 > r1 ){
                 isAdd = bal1 - r1 > addPriceTokenAmount;
            }
            return isAdd;

        
    }
    function _isLiquidity2(address uniswapV2Pair)internal view returns(bool){
        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        ( uint r0,,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        bool isAdd =false;
        uint bal0= IERC20(token0).balanceOf(uniswapV2Pair);
         if(token0 != address(this) && bal0 > r0 ){
                 isAdd = bal0 - r0 > addPriceTokenAmount;
            }
            return isAdd;

        
    }

    function fenhong() public {
        _fenhong();
    }

    function _fenhong() internal {
        if(block.timestamp < (fenhongTime+fenHongPeriod)){
            return;
        }
        uint256 fenhongAmount = _balances[fenHongAddress];
        if(fenhongAmount == 0) return;
        uint256 FETotal =  IERC20(FEuniswapV2Pair).totalSupply();
        uint256 HBTTotal =  IERC20(HBTuniswapV2Pair).totalSupply();
        uint256 USDTTotal =  IERC20(USDTuniswapV2Pair).totalSupply();
        if(FETotal==0 && HBTTotal ==0 && USDTTotal ==0){
            return;
        }
        //type 1
        if(FETotal != 0 && HBTTotal ==0 && USDTTotal == 0){
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0)return;
        uint256 iterations = 0;
        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
          uint256 amount = fenhongAmount.mul(IERC20(FEuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(FETotal);
          if(amount>0){
             _balances[fenHongAddress] = _balances[fenHongAddress].sub(amount);
             _balances[shareholders[currentIndex]] = _balances[shareholders[currentIndex]].add(amount);
             emit Transfer(fenHongAddress, shareholders[currentIndex], amount);
          }
            currentIndex++;
            iterations++;
        }
        }
        //type 2
        if(FETotal != 0 && HBTTotal !=0 && USDTTotal == 0){
        uint256 Afenhong = fenhongAmount.mul(75).div(100);
        uint256 Bfenhong = fenhongAmount.mul(25).div(100);
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0)return;
        uint256 iterations = 0;
        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
          uint256 A = Afenhong.mul(IERC20(FEuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(FETotal);
          uint256 B = Bfenhong.mul(IERC20(HBTuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(HBTTotal);
          uint256 amount = A+B;
          if(amount>0){
             _balances[fenHongAddress] = _balances[fenHongAddress].sub(amount);
             _balances[shareholders[currentIndex]] = _balances[shareholders[currentIndex]].add(amount);
             emit Transfer(fenHongAddress, shareholders[currentIndex], amount);
          }
            currentIndex++;
            iterations++;
        }
        }

        //type 3
        if(FETotal != 0 && HBTTotal ==0 && USDTTotal != 0){
        uint256 Afenhong = fenhongAmount.mul(75).div(100);
        uint256 Bfenhong = fenhongAmount.mul(25).div(100);
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0)return;
        uint256 iterations = 0;
        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
          uint256 A = Afenhong.mul(IERC20(FEuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(FETotal);
          uint256 B = Bfenhong.mul(IERC20(USDTuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(USDTTotal);
          uint256 amount = A+B;
          if(amount>0){
             _balances[fenHongAddress] = _balances[fenHongAddress].sub(amount);
             _balances[shareholders[currentIndex]] = _balances[shareholders[currentIndex]].add(amount);
             emit Transfer(fenHongAddress, shareholders[currentIndex], amount);
          }
            currentIndex++;
            iterations++;
        }
        }

        //type 4
        if(FETotal != 0 && HBTTotal !=0 && USDTTotal != 0){
        uint256 Afenhong = fenhongAmount.mul(50).div(100);
        uint256 Bfenhong = fenhongAmount.mul(25).div(100);
        uint256 Cfenhong = fenhongAmount.mul(25).div(100);
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0)return;
        uint256 iterations = 0;
        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
          uint256 A = Afenhong.mul(IERC20(FEuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(FETotal);
          uint256 B = Bfenhong.mul(IERC20(USDTuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(USDTTotal);
          uint256 C = Cfenhong.mul(IERC20(HBTuniswapV2Pair).balanceOf(shareholders[currentIndex])).div(HBTTotal);
          uint256 amount = A+B+C;
          if(amount>0){
             _balances[fenHongAddress] = _balances[fenHongAddress].sub(amount);
             _balances[shareholders[currentIndex]] = _balances[shareholders[currentIndex]].add(amount);
             emit Transfer(fenHongAddress, shareholders[currentIndex], amount);
          }
            currentIndex++;
            iterations++;
        }
        }
        fenhongTime = block.timestamp;
    }

    function setShare(address shareholder) internal {
           uint256 result = 0;
           if(_updated[shareholder]){   
                if(IERC20(FEuniswapV2Pair).balanceOf(shareholder) != 0) result += 1;
               
                if(IERC20(HBTuniswapV2Pair).balanceOf(shareholder) != 0) result += 1;
               
                if(IERC20(USDTuniswapV2Pair).balanceOf(shareholder) != 0) result += 1;
               
               if(result == 0) quitShare(shareholder);     
                return;  
           } 
            addShareholder(shareholder);
            _updated[shareholder] = true;
          
      }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function quitShare(address shareholder) private {
           removeShareholder(shareholder);   
           _updated[shareholder] = false; 
      }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

}