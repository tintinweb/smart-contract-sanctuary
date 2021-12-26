/**
 *Submitted for verification at snowtrace.io on 2021-12-26
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

interface NODEON_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface MIM_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface DATA_Interface {
    function getAVAXPrice() external view returns (uint price_18);
    function getNEONPrice() external view returns (uint price_18);
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

contract NodeonDapp is Ownable {
    constructor() {
        app = msg.sender;
        temp = msg.sender;
    }

    address nodeDistributor;
    address app;
    address temp;

    address NODEON = 0xAD4715E16aBe7FdB93750788957C061FEDc4850C;
    NODEON_Interface public nodeon = NODEON_Interface(NODEON);
    
    address multisig = 0x656F762083DBCDC0D0386e46D79d5297687e04A6;

    bool nodeCreationOn = true;
    bool claimOn = true;

    mapping (address => uint) public nodeCount;
    mapping (address => uint) public lastClaim;

    uint public totalNodes;
    uint public reward = 0;

    function initSnapshot(address[] memory _users, uint[] memory _amounts, uint start, uint end) public onlyTemp {
        for (uint i = start; i < end + 1; i += 1) {
            nodeCount[_users[i]] = _amounts[i];
            lastClaim[_users[i]] = block.timestamp;
            totalNodes += _amounts[i];
        } 
    }

    function claim() public {
        require(claimOn, "Claim off");

        nodeon.approve(address(this), getPending(msg.sender));
        nodeon.transferFrom(address(this), msg.sender, getPending(msg.sender));

        lastClaim[msg.sender] = block.timestamp;
    }

    function claimFor(address _user) public onlyAppOrNodeDistributor {
        require(claimOn, "Claim off");

        nodeon.approve(address(this), getPending(_user));
        nodeon.transferFrom(address(this), _user, getPending(_user));

        lastClaim[_user] = block.timestamp;
    }

    function setLastClaim(address _user, uint _value) public onlyAppOrNodeDistributor {
        lastClaim[_user] = _value;
    }

    function addNode(address _user, uint _amount) public onlyAppOrNodeDistributor {
        require (nodeCreationOn, "Node creation off");
        claimFor(_user);

        nodeCount[_user] += _amount;
        totalNodes += _amount;
    }

    function removeNode(address _user, uint _amount) public onlyAppOrNodeDistributor {
        claimFor(_user);

        nodeCount[_user] -= _amount;
        totalNodes -= _amount;
    }

    function sendNode(address _from, address _to, uint _amount) public onlyAppOrNodeDistributor {
        require(getNodeCount(_from) >= _amount, "You don't have enough nodes.");

        removeNode(_from, _amount);
        addNode(_to, _amount);
    }

    function giveNode(address _user, uint _amount) public onlyAppOrNodeDistributor {
        addNode(_user, _amount);
    }

    //VIEW

    function getReward() public view returns (uint) {
        return reward;
    }

    function getTotalNodes() public view returns (uint) {
        return totalNodes;
    }

    function getPending(address _user) public view returns (uint) {
        
        uint time = block.timestamp - lastClaim[_user];
        uint total = nodeCount[_user] * time * getReward();

        return total;
    }

    function getNodeCount(address _user) public view returns (uint) {
        return nodeCount[_user];
    }

    function getLastClaim(address _user) public view returns (uint) {
        return lastClaim[_user];
    }

    //OWNER

    function flipNodesCreation() public onlyOwner {
        nodeCreationOn = !nodeCreationOn;
    }

    function flipClaim() public onlyOwner {
        claimOn = !claimOn;
    }

    function setReward(uint _value) public onlyOwner {
        reward = _value;
    }

    function setMultisig(address _addy) public onlyOwner {
        multisig = _addy;
    }

    function setNodeDistributor(address _addy) public onlyOwner {
        nodeDistributor = _addy;
    }
    
    function setApp(address _addy) public onlyOwner {
        app = _addy;
    }
    
    function setTemp(address _addy) public onlyTemp {
        temp = _addy;
    }

    modifier onlyAppOrNodeDistributor() {
        require (msg.sender == nodeDistributor || msg.sender == app, "onlyAppOrNodeDistributor");
        _;
    }

    modifier onlyTemp() {
        require (msg.sender == temp, "onlyTemp");
        _;
    }
}

contract NodeonDistributor is Ownable {

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    address NODEON = 0xAD4715E16aBe7FdB93750788957C061FEDc4850C;
    NODEON_Interface public nodeon = NODEON_Interface(NODEON);
    
    address MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    MIM_Interface public mim = MIM_Interface(MIM);

    address DAPP = 0x36Fc69A2526ae01d862e552f21FE4192Fa4532E1;
    DAPP_Interface public dapp = DAPP_Interface(DAPP);

    address DATA = 0x0AA2De6C6da3160179E7C32BC545d2DFfbc16fA7;
    DATA_Interface public data = DATA_Interface(DATA);

    address DEX = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    DEX_Interface public dex = DEX_Interface(DEX);

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address multisig = 0x656F762083DBCDC0D0386e46D79d5297687e04A6;

    uint nodePrice = 10 * 1e18;
    uint percentReserve = 70;
    uint percentLiquidity = 20;
    uint percentTreasury = 10;

    function buyNodeNEON(uint _amount) public {
        uint value = nodePrice*_amount;

        nodeon.transferFrom(msg.sender, DAPP, value * percentReserve / 100);
        nodeon.transferFrom(msg.sender, multisig, value * percentTreasury / 100);

        address[] memory path = new address[](2);
        path[0] = NODEON;
        path[1] = WAVAX;
        nodeon.transferFrom(msg.sender, address(this), value * percentLiquidity / 100);
        nodeon.approve(DEX, value);
        dex.swapExactTokensForAVAX(
            value * percentLiquidity / 200,
            0,
            path,
            address(this),
            block.timestamp+900);

        uint valueAVAX = data.getNEONPrice() * value / 1e18;
        dex.addLiquidityAVAX{value: valueAVAX * percentLiquidity * 99 / 20000}(
            NODEON,
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
        uint priceAVAX = data.getNEONPrice() * value / 1e18;

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
        path[1] = NODEON;
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
        nodeon.approve(DEX, value);

        //Add AVAX and tokens to liquidity
        dex.addLiquidityAVAX{value: priceAVAX * percentLiquidity / 200}(
            NODEON,
            value * percentLiquidity / 205,
            0,
            0,
            address(0),
            block.timestamp+900);

        //Add node to user
        dapp.addNode(msg.sender, _amount);
    }

    function buyNodeMIM(uint _amount) public {
        uint priceMIM = getNodePriceUSD() * _amount;

        mim.transferFrom(msg.sender, address(this), priceMIM);

        mim.approve(DEX, priceMIM);
        address[] memory path = new address[](2);
        path[0] = MIM;
        path[1] = NODEON;
        dex.swapExactTokensForTokens(
            priceMIM,
            0,
            path,
            msg.sender,
            block.timestamp+900
        );

        buyNodeNEON(_amount);

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
        return nodePrice * data.getNEONPrice() / 1e18;
    }

    function getNodePriceUSD() public view returns (uint) {
        return getNodePriceAVAX() * data.getAVAXPrice();
    }

    function withdraw() public onlyOwner {
        payable(multisig).transfer(address(this).balance);
    }

    function withdrawTokens() public onlyOwner {
        nodeon.transfer(multisig, nodeon.balanceOf(address(this)));
    }
}