/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

interface ITreasury {
  function updateProfits( address paymetAddress, address reserveToken_, address managedToken_ ) external returns ( bool );
}

interface IStaking {

    function initialize(
        address olyTokenAddress_,
        address sOLY_,
        address dai_,
        address olympusTreasuryAddress_
    ) external;

    //function stakeOLY(uint amountToStake_) external {
    function stakeOLY(
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    //function unstakeOLY( uint amountToWithdraw_) external {
    function unstakeOLY(
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function distributeOLYProfits() external;
}

interface IsOLYandOLY {
    function rebase(uint256 olyProfit)
        external
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract OlympusStaking is IStaking, Ownable {
    using SafeMath for uint256;
    using Address for address;

    bool isInitialized;

    address public oly;
    address public sOLY;
    address public dai;
    address public olympusTreasuryAddress;

    uint256 public olyToDistributeNextEpoch;

    modifier notInitialized() {
        require(!isInitialized);
        _;
    }

    function initialize(
        address olyTokenAddress_,
        address sOLY_,
        address dai_,
        address olympusTreasuryAddress_
    ) external override onlyOwner() notInitialized() {
        oly = olyTokenAddress_;
        sOLY = sOLY_;
        dai = dai_;
        olympusTreasuryAddress = olympusTreasuryAddress_;

        isInitialized = true;
    }

    function stakeOLY(
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {
        IsOLYandOLY(oly).permit(
            msg.sender,
            address(this),
            amountToStake_,
            deadline_,
            v_,
            r_,
            s_
        );
        
        ITreasury( olympusTreasuryAddress ).updateProfits( address(this), dai, oly );

        require(
            IsOLYandOLY(oly).transferFrom(
                msg.sender,
                address(this),
                amountToStake_
            )
        );

        IsOLYandOLY(sOLY).transfer(msg.sender, amountToStake_);
    }

    function unstakeOLY(
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {
        ITreasury( olympusTreasuryAddress ).updateProfits( address(this), dai, oly );

        IsOLYandOLY(sOLY).permit(
            msg.sender,
            address(this),
            amountToWithdraw_,
            deadline_,
            v_,
            r_,
            s_
        );

        require(IsOLYandOLY(sOLY).transferFrom(
            msg.sender,
            address(this),
            amountToWithdraw_
        ), "Not enough stake");

        require(
            IsOLYandOLY(oly).transfer(msg.sender, amountToWithdraw_),
            "Claim Failed"
        );
    }

    function distributeOLYProfits() external override onlyOwner() {
        //console.log(msg.sender);
        IsOLYandOLY(sOLY).rebase(olyToDistributeNextEpoch);

        uint256 _olyBalance = IsOLYandOLY(oly).balanceOf(address(this));
        uint256 _solySupply = IsOLYandOLY(sOLY).circulatingSupply();

        olyToDistributeNextEpoch = _olyBalance.sub(_solySupply);
    }
}