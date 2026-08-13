/**
 *Submitted for verification at hecoinfo.com on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract BalanceTools {

    mapping(address => bool) _dictinctTools;

    mapping(uint256 => address) _user;

    uint256 autoIncrement;

    address private _gate;

    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyGate() {
        require(_gate == msg.sender, "Ownable: caller is not the gate");
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    function setGate(address __gate) external onlyOwner
    {
        _gate = __gate;
    }

    function write(address _sender) external onlyGate
    {
        if (_dictinctTools[_sender] == false)
        {
            _dictinctTools[_sender] = true;
            _user[autoIncrement] = _sender;
            autoIncrement++;
        }
    }

    function getLength() external view returns (uint256)
    {
        return autoIncrement;
    }

    function balanceOfTotal(address _tokenContract, uint256 start, uint256 end) external view returns (uint256)
    {
        uint256 _balanceOfTotal = 0;
        for (uint256 i=start; i<=end; i++)
        {
            if (_tokenContract == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            {
                _balanceOfTotal += _user[i].balance;
            }
            else
            {
                _balanceOfTotal += IERC20(_tokenContract).balanceOf(_user[i]);
            }
        }
        return _balanceOfTotal;
    }
}