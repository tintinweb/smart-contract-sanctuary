// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface TokenInterface {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Liquidity is Ownable {
    address public DEX;
    string[] public allLiquidities;
    mapping(string => address) public contractAddress;

    event DEXUpdated(address oldDEX, address newDEX);
    event TokenUpdated(string symbol, address newContract);
    event PaymentReceived(address from, uint256 amount);
    event LiquidityWithdraw(
        string symbol,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event LiquidityTransfer(
        string symbol,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Throws if called by any account other than the DEX.
     */
    modifier onlyDEX() {
        require(DEX == _msgSender(), "Liquidity: caller is not DEX");
        _;
    }

    constructor(
        address owner,
        address gsu,
        address usdt
    ) public {
        require(owner != address(0x0), "[Liquidity], owner is zero address");
        require(gsu != address(0x0), "[Liquidity], gsu is zero address");
        require(usdt != address(0x0), "[Liquidity], usdt is zero address");

        allLiquidities.push("ETH");

        newLiquidity(gsu);
        newLiquidity(usdt);
        transferOwnership(owner);
    }

    fallback() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function withdraw(string calldata symbol, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "[Liquidity] amount is zero");

        if (isERC20Token(symbol))
            TokenInterface(contractAddress[symbol]).transfer(owner(), amount);
        else address(uint160(owner())).transfer(amount);

        emit LiquidityWithdraw(symbol, owner(), amount, block.timestamp);
    }

    function transfer(
        string calldata symbol,
        address payable recipient,
        uint256 amount
    ) external onlyDEX returns (bool) {
        if (isERC20Token(symbol))
            TokenInterface(contractAddress[symbol]).transfer(recipient, amount);
        else recipient.transfer(amount);

        emit LiquidityTransfer(symbol, recipient, amount, block.timestamp);

        return true;
    }

    function balanceOf(string memory symbol) public view returns (uint256) {
        if (isERC20Token(symbol))
            return
                TokenInterface(contractAddress[symbol]).balanceOf(
                    address(this)
                );
        else return address(this).balance;
    }

    function isERC20Token(string memory symbol) public view returns (bool) {
        return contractAddress[symbol] != address(0x0);
    }

    function updateDEX(address newDEX) external onlyOwner returns (bool) {
        emit DEXUpdated(DEX, newDEX);
        DEX = newDEX;
        return true;
    }

    function newLiquidity(address _contract) private onlyOwner returns (bool) {
        string memory symbol = TokenInterface(_contract).symbol();
        allLiquidities.push(symbol);
        contractAddress[symbol] = _contract;
        return true;
    }

    function setTokenContract(string calldata symbol, address newContract)
        external
        onlyOwner
        returns (bool)
    {
        require(isERC20Token(symbol));
        contractAddress[symbol] = newContract;
        emit TokenUpdated(symbol, newContract);
        return true;
    }

    function totalLiquidities() external view returns (uint256) {
        return allLiquidities.length;
    }

    function destroy() external onlyOwner {
        // index 0 is ethereum
        for (uint8 a = 1; a < allLiquidities.length; a++) {
            string memory currency = allLiquidities[a];
            TokenInterface(contractAddress[currency]).transfer(
                owner(),
                balanceOf(currency)
            );
        }

        selfdestruct(payable(owner()));
    }
}