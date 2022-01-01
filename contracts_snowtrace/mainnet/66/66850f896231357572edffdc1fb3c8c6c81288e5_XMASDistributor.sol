/**
 *Submitted for verification at snowtrace.io on 2021-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: AVAX_TRANSFER_FAILED');
    }
}

interface XMAS_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface DATA_Interface {
    function getAVAXPrice() external view returns (uint price_18);
    function getXMASPrice() external view returns (uint price_18);
}

interface DAPP_Interface {
    function addNode(address _user, uint _amount) external;
    function removeNode(address _user, uint _amount) external;
    function claim() external;
    function setLastClaim(address _user, uint _value) external;
    function getNodeCount(address _user) external view returns (uint);
    function getPending(address _user) external view returns (uint);
    function giveNode(address _user, uint _amount) external;
}

interface DEX_Interface {
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForAVAX(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract XMASDistributor is Ownable {

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    address XMAS = 0xbf77597b47491F3D341de5373aC7ab418e9e9fe2;
    XMAS_Interface public xmas = XMAS_Interface(XMAS);

    address DAPP = 0x49F8359fB10225f0714a9d47d6378249B75573D6;
    DAPP_Interface public dapp = DAPP_Interface(DAPP);

    address DATA = 0x1d6374150A835A91616Bffa37FC431f13c05c207;
    DATA_Interface public data = DATA_Interface(DATA);

    address DEX = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    DEX_Interface public dex = DEX_Interface(DEX);

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address multisig = 0x656F762083DBCDC0D0386e46D79d5297687e04A6;

    uint nodePrice = 10 * 1e18;
    uint percentReserve = 70;
    uint percentLiquidity = 20;
    uint percentTreasury = 10;

    function buyNodeXMAS(uint _amount) public {
        uint value = nodePrice*_amount;

        xmas.transferFrom(msg.sender, DAPP, value * percentReserve / 100);
        xmas.transferFrom(msg.sender, multisig, value * percentTreasury / 100);

        address[] memory path = new address[](2);
        path[0] = XMAS;
        path[1] = WAVAX;
        xmas.transferFrom(msg.sender, address(this), value * percentLiquidity / 100);
        xmas.approve(DEX, value);
        dex.swapExactTokensForAVAX(
            value * percentLiquidity / 200,
            0,
            path,
            address(this),
            block.timestamp+900);

        uint valueAVAX = data.getXMASPrice() * value / 1e18;
        dex.addLiquidityAVAX{value: valueAVAX * percentLiquidity * 99 / 20000}(
            XMAS,
            value * percentLiquidity / 200,
            0,
            0,
            address(0),
            block.timestamp+900);

        dapp.addNode(msg.sender, _amount);
    }

    function buyNodeAVAX(uint _amount) public payable {
        require(_amount <= 10, "You can't buy more than 10 nodes in a single tx.");

        //Node price in token
        uint value = nodePrice*_amount;

        //Node price in AVAX
        uint priceAVAX = data.getXMASPrice() * value / 1e18;

        //Check sent amount
        require(msg.value >= priceAVAX, "Wrong value.");

        //Send in the treasury in the treasury (10%)
        TransferHelper.safeTransferAVAX(multisig, priceAVAX * percentTreasury / 100);

        //Check if msg.value is higher than expected and send funds back
        if (msg.value > priceAVAX) {
            TransferHelper.safeTransferAVAX(msg.sender, msg.value - priceAVAX);
        }

        //Swap reserve percentage from AVAX to tokens (70%)
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = XMAS;
        dex.swapExactAVAXForTokens{value: priceAVAX * percentReserve / 100}(
            0,
            path,
            DAPP,
            block.timestamp+900
        );

        //Swap half of the liquidity percentage from AVAX to tokens (half of 20%)
        dex.swapExactAVAXForTokens{value: priceAVAX * percentLiquidity / 200}(
            0,
            path,
            address(this),
            block.timestamp+900
        );

        //Approve the DEX to transfer tokens from this contract
        xmas.approve(DEX, value);

        //Add AVAX and tokens to liquidity
        dex.addLiquidityAVAX{value: priceAVAX * percentLiquidity / 200}(
            XMAS,
            value * percentLiquidity / 205,
            0,
            0,
            address(0),
            block.timestamp+900);

        //Add node to user
        dapp.addNode(msg.sender, _amount);
    }

    function setPercentages(uint reserve, uint liquidity, uint treasury) public onlyOwner {
        require(reserve + liquidity + treasury == 100);
        require(treasury <= 25);

        percentReserve = reserve;
        percentLiquidity = liquidity;
        percentTreasury = treasury;

    }

    function getNodePrice() public view returns (uint) {
        return nodePrice;
    }

    function getNodePriceAVAX() public view returns (uint) {
        return nodePrice * data.getXMASPrice() / 1e18;
    }

    function getNodePriceUSD() public view returns (uint) {
        return getNodePriceAVAX() * data.getAVAXPrice();
    }

    function withdraw() public onlyOwner {
        payable(multisig).transfer(address(this).balance);
    }

    function withdrawTokens() public onlyOwner {
        xmas.transfer(multisig, xmas.balanceOf(address(this)));
    }
}