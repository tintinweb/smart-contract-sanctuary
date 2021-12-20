/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

    // OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev Provides information about the current execution context, including the
    * sender of the transaction and its data. While these are generally available
    * via msg.sender and msg.data, they should not be accessed in such a direct
    * manner, since when dealing with meta-transactions the account sending and
    * paying for execution may not be the actual sender (as far as an application
    * is concerned).
    *
    * This contract is only required for intermediate, library-like contracts.
    */
    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }

        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }

    // File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

    // OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev Contract module which provides a basic access control mechanism, where
    * there is an account (an owner) that can be granted exclusive access to
    * specific functions.
    *
    * By default, the owner account will be the one that deploys the contract. This
    * can later be changed with {transferOwnership}.
    *
    * This module is used through inheritance. It will make available the modifier
    * `onlyOwner`, which can be applied to your functions to restrict their use to
    * the owner.
    */
    abstract contract Ownable is Context {
        address private _owner;

        event OwnershipTransferred(
            address indexed previousOwner,
            address indexed newOwner
        );

        /**
        * @dev Initializes the contract setting the deployer as the initial owner.
        */
        constructor() {
            _transferOwnership(_msgSender());
        }

        /**
        * @dev Returns the address of the current owner.
        */
        function owner() public view virtual returns (address) {
            return _owner;
        }

        /**
        * @dev Throws if called by any account other than the owner.
        */
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }

        /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
        function renounceOwnership() public virtual onlyOwner {
            _transferOwnership(address(0));
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(
                newOwner != address(0),
                "Ownable: new owner is the zero address"
            );
            _transferOwnership(newOwner);
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Internal function without access restriction.
        */
        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }

    // File: contracts/bridge.sol

    //SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.0;

    // import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
    interface IERC20 {
        /**
        * @dev Returns the amount of tokens in existence.
        */
        function totalSupply() external view returns (uint256);

        /**
        * @dev Returns the amount of tokens owned by `account`.
        */
        function balanceOf(address account) external view returns (uint256);

        /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transfer(address recipient, uint256 amount)
            external
            returns (bool);

        /**
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve} or {transferFrom} are called.
        */
        function allowance(address owner, address spender)
            external
            view
            returns (uint256);

        /**
        * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * IMPORTANT: Beware that changing an allowance with this method brings the risk
        * that someone may use both the old and the new allowance by unfortunate
        * transaction ordering. One possible solution to mitigate this race
        * condition is to first reduce the spender's allowance to 0 and set the
        * desired value afterwards:
        * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        *
        * Emits an {Approval} event.
        */
        function approve(address spender, uint256 amount) external returns (bool);

        /**
        * @dev Moves `amount` tokens from `sender` to `recipient` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) external returns (bool);

        /**
        * @dev Emitted when `value` tokens are moved from one account (`from`) to
        * another (`to`).
        *
        * Note that `value` may be zero.
        */

        function burnFrom(address account, uint256 amount) external;

        function mint(address account, uint256 amount) external;

        event Transfer(address indexed from, address indexed to, uint256 value);

        /**
        * @dev Emitted when the allowance of a `spender` for an `owner` is set by
        * a call to {approve}. `value` is the new allowance.
        */
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
    }

    pragma solidity ^0.8.0;

    contract WRAPPER is Ownable {
        mapping(address => string[]) txHashes;
        mapping(address => bool) public isWhitelisted;
        mapping(address => bool) public isPegged;
        mapping(address => bool) public isMinted;
        mapping(string => address) public whitelistedTokenAddress;
        mapping(address => string) public whitelistedTokenName;
        mapping(address => uint256) bridgeFee;
        bool public isBlocked;
        uint256 bridgeFeePercent = 5;
        string[] public whitelistedTokenNames;
        uint256 index = 1;
        mapping(string => uint256) public mapWhiltelistTokenNames;

        event DEPOSIT(
            uint256 tamount,
            address sender,
            string txhash,
            address tokenAddress,
            string tokenName
        );
        event WITHDRAW(uint256 amount, address sender, address tokenAddress);

        constructor() {}

        //Functions to block or unblock the bridge
        function blockBridge() external onlyOwner returns (bool) {
            isBlocked = true;
            return true;
        }

        function unblockBridge() external onlyOwner returns (bool) {
            isBlocked = false;
            return true;
        }

        //Initialization Minted Tokens
        function makeMintedToken(address tokenAddress)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            isMinted[tokenAddress] = true;
            return true;
        }

        function removeMintedToken(address tokenAddress)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            isMinted[tokenAddress] = false;
            return true;
        }

        //Initialization of Pegged Tokens
        function makePegToken(address tokenAddress)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            isPegged[tokenAddress] = true;
            return true;
        }

        function removePegToken(address tokenAddress)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            isPegged[tokenAddress] = false;
            return true;
        }

        //Whitelisting and Initializing of Tokens
        function whitelistToken(address tokenAddress, string memory tokenName)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            require(!ifDuplicateTokenName(tokenName), "Duplicate token name");
            isWhitelisted[tokenAddress] = true;
            whitelistedTokenName[tokenAddress] = tokenName;
            whitelistedTokenAddress[tokenName] = tokenAddress;
            whitelistedTokenNames.push(tokenName);
            mapWhiltelistTokenNames[tokenName] = index;
            index++;
            return true;
        }

        function ifDuplicateTokenName(string memory tokenName) private view returns (bool){
            bool flag = false;
            for (uint256 j=0; j < whitelistedTokenNames.length; j++){
                if(
                    keccak256(abi.encodePacked(whitelistedTokenNames[j])) == keccak256(abi.encodePacked(tokenName))
                ) {
                    flag = true;
                    break;
                }
            }
            return flag;
            
        } 

        function removeTokenFromWhitelist(address tokenAddress, address receiver)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            IERC20(tokenAddress).transfer(receiver, bridgeFee[tokenAddress]);
            string memory tokenName = whitelistedTokenName[tokenAddress];
            delete whitelistedTokenAddress[tokenName];
            delete whitelistedTokenName[tokenAddress];
            uint256 i = mapWhiltelistTokenNames[tokenName];
            string memory lastTokenName = whitelistedTokenNames[((whitelistedTokenNames.length) - 1)];
            mapWhiltelistTokenNames[lastTokenName]=i;
            whitelistedTokenNames[i-1] = lastTokenName;
            whitelistedTokenNames.pop();
            delete mapWhiltelistTokenNames[tokenName];
            isWhitelisted[tokenAddress] = false;
            return true;
        }

        //Core Bridge Logic
        function deposit(
            uint256 amount,
            string memory _txhash,
            address tokenAddress
        ) external returns (bool) {
            //approve address(this) to transfer your tokens that you want to deposit and get your wrapped tokens
            require(tokenAddress != address(0), "Cannot be address 0");
            require(isBlocked != true, "Bridge is blocked right now");
            require(
                isWhitelisted[tokenAddress] == true,
                "This token is not Whitelisted on our platform"
            );
            require(
                amount <= IERC20(tokenAddress).balanceOf(msg.sender),
                "Amount exceeds your balance"
            );
            string[] memory _txHashes = txHashes[msg.sender];
            for (uint256 i = 0; i < _txHashes.length; i++) {
                if (
                    keccak256(abi.encodePacked(_txhash)) ==
                    keccak256(abi.encodePacked(_txHashes[i]))
                ) revert("This transaction hash has already been used");
            }
            txHashes[msg.sender].push(_txhash);

            uint256 tamount = amount;
            if (isPegged[tokenAddress] == true)
                IERC20(tokenAddress).burnFrom(msg.sender, tamount);
            else if (isMinted[tokenAddress] == true) {
                require(
                    IERC20(tokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        amount
                    ),
                    "There was a problem transferring your bep tokens"
                );
            } else {
                bridgeFee[tokenAddress] =
                    bridgeFee[tokenAddress] +
                    ((amount * bridgeFeePercent) / 1000);
                tamount = amount - ((amount * bridgeFeePercent) / 1000);
                require(
                    IERC20(tokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        amount
                    ),
                    "There was a problem transferring your bep tokens"
                );
            }
            emit DEPOSIT(
                tamount,
                msg.sender,
                _txhash,
                tokenAddress,
                whitelistedTokenName[tokenAddress]
            );
            return true;
        }

        function withdraw(
            uint256 amount,
            address tokenAddress,
            address receiver
        ) external onlyOwner returns (bool) {
            require(tokenAddress != address(0), "Cannot be address 0");
            require(receiver != address(0), "Cannot be address 0");
            require(
                isWhitelisted[tokenAddress] == true,
                "This token is not Whitelisted on our platform"
            );
            if (isPegged[tokenAddress] == true)
                IERC20(tokenAddress).mint(receiver, amount);
            else if (isMinted[tokenAddress] == true) {
                require(
                    IERC20(tokenAddress).transfer(receiver, amount),
                    "There was a problem transferring your tokens"
                );
            } else {
                bridgeFee[tokenAddress] =
                    bridgeFee[tokenAddress] +
                    ((amount * bridgeFeePercent) / 1000);
                amount = amount - ((amount * bridgeFeePercent) / 1000);
                require(
                    IERC20(tokenAddress).transfer(receiver, amount),
                    "There was a problem transferring your tokens"
                );
            }
            emit WITHDRAW(amount, receiver, tokenAddress);
            return true;
        }

        //Function to change the bridge fee percentage
        function changeBridgeFee(uint256 value) external onlyOwner returns (bool) {
            require(value != 0, "Value cannot be 0");
            bridgeFeePercent = value;
            return true;
        }

        //Function to get names of all whitelisted tokens
        function getAllWhitelistedTokenNames()
            external
            view
            returns (string[] memory)
        {
            return whitelistedTokenNames;
        }

        //Bridge Fee collection
        function getSingleTokenBridgeFee(address tokenAddress)
            external
            view
            onlyOwner
            returns (uint256)
        {
            return bridgeFee[tokenAddress];
        }

        function claimSingleTokenBridgeFee(address tokenAddress, address receiver)
            external
            onlyOwner
            returns (bool)
        {
            require(tokenAddress != address(0), "Cannot be address 0");
            require(receiver != address(0), "Cannot be address 0");
            uint256 fee = bridgeFee[tokenAddress];
            bridgeFee[tokenAddress] = 0;
            require(
                IERC20(tokenAddress).transfer(receiver, fee),
                "There was a problem transferring your tokens"
            );
            return true;
        }

        function claimAllTokenBridgeFee(address receiver)
            external
            onlyOwner
            returns (bool)
        {
            require(receiver != address(0), "Cannot be address 0");
            for (uint256 i = 0; i < whitelistedTokenNames.length; i++) {
                address tokenAddress = whitelistedTokenAddress[
                    whitelistedTokenNames[i]
                ];
                uint256 fee = bridgeFee[tokenAddress];
                bridgeFee[tokenAddress] = 0;
                require(
                    IERC20(tokenAddress).transfer(receiver, fee),
                    "There was a problem transferring your tokens"
                );
            }

            return true;
        }
    }