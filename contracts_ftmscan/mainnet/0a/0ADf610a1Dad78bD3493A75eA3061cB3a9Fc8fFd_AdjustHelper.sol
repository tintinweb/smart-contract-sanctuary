/**
 *Submitted for verification at FtmScan.com on 2021-12-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBond{
    function totalDebt() external view returns(uint);
    function isLiquidityBond() external view returns(bool);
    function bondPrice() external view returns ( uint );
    function terms() external view returns(
        uint _controlVariable, // scaling variable for price
        uint _vestingTerm, // in blocks
        uint _minimumPrice, // vs principle value
        uint _maxPayout, // in thousandths of a %. i.e. 500 = 0.5%
        uint _fee, // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint _maxDebt // 9 decimal debt ratio, max % total supply created as debt
    );
}

contract AdjustHelper is Ownable {
    using SafeMath for uint;
    using Address for address;

    mapping( address => bool ) public bonds;

    function addBondContract(address _bond) external onlyOwner() {
        // make sure that the bond is available
        IBond(_bond).terms();
        IBond(_bond).isLiquidityBond();
        bonds[_bond] = true;
    }
    
    function removeBondContract(address _bond) external onlyOwner() {
        delete bonds[_bond];
    }
    
    /**
     *  @notice recalculate the price of bond based on the percent
     *  @param _bond address
     *  @param _percent uint, 1000 = 1.0000%
     *  @return _newPrice uint
     */
    function recalculate(address _bond, uint _percent) view internal returns( uint ) {
        if (IBond(_bond).isLiquidityBond()) {
            return _percent;
        } else{
            uint _price = IBond(_bond).bondPrice();
            uint _newPrice = _price.mul(_percent).sub(1000000).div(_price.sub(100));
            return _newPrice;
        }
    }

    /**
     *  @notice view the price adjust result
     *  @param _bond address
     *  @param _percent uint, 1000 = 1.000%
     *  @return _newControlVariable uint
     *  @return _vestingTerm uint
     *  @return _newMinimumPrice uint
     *  @return _maxPayout uint
     *  @return _fee uint
     *  @return _maxDebt uint
     *  @return _initialDebt uint
     */
    function priceResult(address _bond, uint _percent) view public returns ( 
        uint _newControlVariable, 
        uint _vestingTerm, 
        uint _newMinimumPrice, 
        uint _maxPayout, 
        uint _fee, 
        uint _maxDebt, 
        uint _initialDebt
     ){
         uint _oldControlVariable = 0;
         uint _oldMinimumPrice = 0;
        (
            _oldControlVariable, 
            _vestingTerm,
            _oldMinimumPrice,
            _maxPayout,
            _fee,
            _maxDebt
        ) = IBond(_bond).terms();

        if (_oldMinimumPrice == 0) {
            _newControlVariable = _oldControlVariable.mul( recalculate(_bond, _percent) ).div(100000);
            _newMinimumPrice = _oldMinimumPrice;
        } else {
            _newControlVariable = _oldControlVariable;
            _newMinimumPrice = _oldMinimumPrice.mul(_percent).div(100000);
        }    
        _initialDebt = IBond(_bond).totalDebt();
    }
}