/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
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

contract Marx is IERC20, IERC20Metadata, Context, Ownable{
    using SafeMath for uint256;
    using Address for address;
    
    event NewCommunist(uint256 id, address communist);
    event DividendPayment(address communist, uint256 myDividends);
        
    string private _name = "Marx13";
    string private _symbol = "MARX13";
    uint8 private _decimals = 4;
    uint256 private _totalSupply;
    uint256 private _totalCommunists;
    uint256 private surplusValueTime = 1 days;
    uint256 private _idCommunist;
    address public dividendsAccount = 0x10241dde03634B6B8D14f15227F9FDD7554D54fd;

    struct Communist{
        address communist;
        uint256 idCommunist;
        uint256 readySurplusValue;
        uint256 surplusValue;
        uint256 totalSurplusValue;
    }
    
    Communist[] _communists1;
    
    mapping (uint => Communist) _communists;
    mapping (address => Communist) addressCommunist;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    
    //Mais Valia = surplus value 
    
   function withdrawDividends(address communist) public isCommunist(msg.sender) {
        require(balanceOf(communist) > 0,"MARX: Communist non detected");
        require(balanceOf(dividendsAccount) > 0, "MARX: Dividends non detected");
        uint256 myDividends = addressCommunist[communist].surplusValue;
        _transfer(dividendsAccount, communist, myDividends);
        
        emit DividendPayment(communist, myDividends);
    }
    
/*    function _calculateSurplusValue(Communist storage _communist, uint256 _amount) private {
        for(uint256 i = 0; i < _totalCommunists; i++){
            _communist.surplusValue += _amount.div(_totalCommunists);
        }
    }
    
    function _calculateWithdrawbleSurplusValue(address _communist, uint256 _surplusValue) public isCommunist(msg.sender) {
        uint256 oldSurplusValue = addressCommunist[_communist].surplusValue;
        uint256 newSurplusValue = _surplusValue - oldSurplusValue;
        addressCommunist[_communist].surplusValue = newSurplusValue;
    }
    
    function _calculateSurplusValue(Communist storage _communist) private view returns (uint256) {
        uint256 surplusValueReleased = _communist.surplusValue;
        return surplusValueReleased;
    }
    
    function _updateSurplusValue(Communist storage _communist, uint256 _amount) private {
        _communist.surplusValue += _amount.div(_totalCommunists);
    }
    
    function _updateTotalSurplusValue(Communist storage _communist, uint256 _mySurplusValue) private {
        _communist.totalSurplusValue += _mySurplusValue;
    } */

    //função para criar um novo comunista
    function _createCommunist(address _communist) private returns (uint256 id) {
        id = _idCommunist.add(1);
        Communist storage newCommunist = _communists[id];
        newCommunist.communist = _communist;
        newCommunist.readySurplusValue = uint256(block.timestamp.add(surplusValueTime));
        newCommunist.surplusValue = 0;
        newCommunist.totalSurplusValue = 0;
        emit NewCommunist(id, _communist);
    }
    
     function myIdCommunist() public view virtual returns (uint256) {
        return addressCommunist[msg.sender].idCommunist;
    }
    
    function _limitSurplusValue(Communist storage _communist) private {
        _communist.readySurplusValue = uint256(block.timestamp.add(surplusValueTime));
    }
    
    function _isReadySurplusValue(Communist storage _communist) private view returns (bool) {
        return (_communist.readySurplusValue <= block.timestamp);
    }
    
    modifier isCommunist(address _communist) {
        require(_communist != address(0));
        require(balanceOf(msg.sender) > 0);
        _;
    }
    
    function calculateDividends() public view returns (uint256) {
        return balanceOf(dividendsAccount).div(_totalCommunists);
    }
    
    function _mintCashback(address _account, uint256 _amount) private {
        _account = msg.sender;
        _mint(_account, _amount);
    }
    
    function _mintDividends(address _account, uint256 _amount) private {
        _mint(_account, _amount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
     function totalCommunists() public view virtual returns (uint256) {
        return _totalCommunists;
    }
    
     function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferNormal(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
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
        require(currentAllowance >= amount, "MARX: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "MARX: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "MARX: transfer from the zero address");
        require(recipient != address(0), "MARX: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "MARX: transfer amount exceeds balance");
        
        uint256 recipientBalance = _balances[recipient];
        
        if(senderBalance == amount && recipientBalance == 0){
            _totalCommunists -= 1;
            _createCommunist(recipient);
            _mintDividends(dividendsAccount, amount.div(20));
        } else if (senderBalance >= amount && recipientBalance == 0){
            _totalCommunists += 1;
            _createCommunist(recipient);
            _mintDividends(dividendsAccount, amount.div(20));
            _mintCashback(_msgSender(),amount.div(50));
        }
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);

    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "MARX: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        uint256 accountBalance = _balances[account];
        if(accountBalance == 0){
            _totalCommunists += 1;
            _createCommunist(account);
        }
        
        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "MARX: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "MARX: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "MARX: approve from the zero address");
        require(spender != address(0), "MARX: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    
}