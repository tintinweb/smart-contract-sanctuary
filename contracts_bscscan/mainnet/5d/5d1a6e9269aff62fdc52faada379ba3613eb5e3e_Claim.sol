/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface MasterChef {
    function userInfo(uint256 pid, address userAddress)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}

contract Claim {
    using Address for address;

    MasterChef public master;
    address public owner;
    IBEP20 public token;

    uint8 public poolId;

    mapping(address => bool) public withdrawn;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Withdrawn(address indexed user, uint256 indexed amount);

    constructor(
        address _master,
        address _owner,
        address _token
    ) {
        master = MasterChef(_master);
        owner = _owner;
        token = IBEP20(_token);
        poolId = 0;
    }

    function get(uint256 pid, address userAddress)
        public
        view
        returns (uint256 amount, uint256 rewardDebt)
    {
        return master.userInfo(pid, userAddress);
    }

    function withdraw() public {
        require(!withdrawn[msg.sender]);
        require(
            !address(msg.sender).isContract(),
            "contracts can not call this function"
        );
        (uint256 amount, ) = get(poolId, msg.sender);
        require(amount > 0, "amount must be greater than zero");

        token.transferFrom(owner, msg.sender, amount);
        withdrawn[msg.sender] = true;

        emit Withdrawn(msg.sender, amount);
    }

    function changePoolId(uint8 _poolId) external onlyOwner {
        poolId = _poolId;
    }

    function changeOwner(address _new) external onlyOwner {
        owner = _new;
    }

    function changeMasterchef(address _new) external onlyOwner {
        master = MasterChef(_new);
    }

    function changeToken(address _new) external onlyOwner {
        token = IBEP20(_new);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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