/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

/**
 *Submitted for verification at Etherscan.io on 2020-01-22
*/

pragma solidity 0.5.16;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EthStation is Ownable {
    address payable[] public accounts;

    event AddAccount(address _account);
    event RemoveAccount(address _account);
    
    function addAccounts(address payable[] calldata _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _addAccount(_accounts[i]);
        }
    }

    function _addAccount(address payable _account) private {
        accounts.push(_account);
        emit AddAccount(_account);
    }

    function removeAccount(address payable _account, uint256 _index) external onlyOwner {
        require(accounts[_index] == _account, "ethstation: account and index should match");
        address payable last = accounts[accounts.length - 1];
        accounts[_index] = last;
        accounts.length--;
        emit RemoveAccount(_account);
    }

    function _balance(uint256 _target, uint256[] memory _balances) internal pure returns (uint256 nTarget) {
        uint256 d = _balances.length;
        uint256 oTarget = _target / _balances.length;

        uint256 t;

        for (uint256 i = 0; i < _balances.length; i++) {
            if (_balances[i] > oTarget) {
                d--;
                t += (_balances[i] - oTarget);
            }
        }

        nTarget = oTarget - (t / d);
    }

    function balances() external view returns (uint256[] memory balances) {
        address payable[] memory maccounts = accounts;
        uint256 length = maccounts.length;

        balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            balances[i] = maccounts[i].balance;
        }
    }
    
    function lowest() external view returns (address, uint256) {
        address payable[] memory maccounts = accounts;
        uint256 length = maccounts.length;
        
        address lowestAddr;
        uint256 lowestBalance;

        for (uint256 i = 0; i < length; i++) {
            address addr = maccounts[i];
            uint256 balance  = addr.balance;

            if (lowestAddr == address(0)) {
                lowestAddr = addr;
                lowestBalance = balance;
            } else {
                if (balance < lowestBalance) {
                    lowestAddr = addr;
                    lowestBalance = balance;
                }
            }
        }

        return (lowestAddr, lowestBalance);
    }

    function() external payable {
        address payable[] memory maccounts = accounts;
        uint256 length = maccounts.length;

        uint256[] memory balances = new uint256[](length);
        uint256 totalBalance;
        
        for (uint256 i = 0; i < length; i++) {
            uint256 balance = maccounts[i].balance;
            totalBalance += balance;
            balances[i] = balance;
        }

        uint256 nTarget = _balance(address(this).balance + totalBalance, balances);

        for (uint256 i = 0; i < length; i++) {                        
            if (balances[i] < nTarget) {
                maccounts[i].call.value(nTarget - balances[i])("");
            }
        }

        msg.sender.transfer(address(this).balance);
    }

    function kill() external onlyOwner {
        selfdestruct(address(uint160(owner())));
    }
}