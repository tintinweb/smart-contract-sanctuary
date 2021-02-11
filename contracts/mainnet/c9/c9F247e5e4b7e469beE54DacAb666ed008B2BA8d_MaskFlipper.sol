/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/mask_flipper.sol
pragma solidity >=0.6.7 <0.7.0;

////// src/mask_flipper.sol
/* pragma solidity ^0.6.7; */

interface NFTX  {
    function mint(uint256 vaultId, uint256[] calldata nftIds, uint256 d2Amount) external;
    function redeem(uint vaultId, uint256 amount) external;
}
interface ERC721 {
    function transferFrom(address from, address to, uint nftID) external;
    function ownerOf(uint nftID) external returns (address);
    function approve(address usr, uint amount) external;
    function tokenOfOwnerByIndex(address owner, uint idx) external returns(uint);
}

interface ERC20 {
    function approve(address usr, uint amount)  external;
    function transferFrom(address from, address to, uint amount) external;
    function balanceOf(address usr) external returns(uint amount);
}

interface SushiRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns(uint[] memory);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns(uint[] memory);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract MaskFlipper {
    // constants
    uint constant public ONE = 10**27;
    uint constant public ONE_MASK_TOKEN = 1 ether;
    // hashmasks vault id
    uint constant public VAULT_ID = 20;

    //math functions
    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }
    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    NFTX public nftx;
    SushiRouter public sushiRouter;
    ERC721 public hashmasks;
    ERC20 public maskToken;
    ERC20 public weth;

    // percentage of WETH send back to the msg.sender denominated in RAY (10^27)
    // default 100% (max value)
    uint public flipMaskRate = ONE;
    // percentage from the floor price required from the user for getRandomMask
    // min value 100%
    uint public getMaskRate = ONE;
    // amountOutMin tolerance from floor price in sushi Swap
    // default 100% (no tolerance)
    uint public tolerance = ONE;
    address public owner;

    constructor(address nftx_, address sushiRouter_, address hashmasks_, address maskToken_, address weth_) public {
        owner = msg.sender;
        nftx = NFTX(nftx_);
        sushiRouter = SushiRouter(sushiRouter_);
        hashmasks = ERC721(hashmasks_);
        maskToken = ERC20(maskToken_);
        weth = ERC20(weth_);

        maskToken.approve(address(sushiRouter), uint(-1));
        weth.approve(address(sushiRouter), uint(-1));
        maskToken.approve(address(nftx), uint(-1));
    }

    function file(bytes32 name, uint value) public {
        require(msg.sender == owner, "msg.sender not owner");
        if(name == "flipMaskRate") {
            flipMaskRate = value;
        } else if(name == "tolerance") {
            tolerance = value;
        } else if(name == "getMaskRate") {
            require(value >= ONE);
            getMaskRate = value;
        } else {
            revert("unknown-config");
        }
    }

    // returns the current floor price minus the fee in WETH
    // amount of WETH received for one hashmask
    function currentFloor() public view returns(uint) {
        return rmul(_currentFloor(), flipMaskRate);
    }

    function _currentFloor() internal view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(maskToken);
        path[1] = address(weth);

        return sushiRouter.getAmountsOut(ONE_MASK_TOKEN, path)[1];
    }

    // amount of WETH required for one hashmask
    function currentGetMaskPrice() public returns(uint) {
        return rmul(_currentMaskTokenPrice(), getMaskRate);
    }

    function _currentMaskTokenPrice() internal returns(uint) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(maskToken);

        return sushiRouter.getAmountsIn(ONE_MASK_TOKEN, path)[0];
    }

    // flip a mask against the current floor price in NFTX and receive WETH back
    function flipMask(uint nftID) public returns(uint payoutAmount){
        require(hashmasks.ownerOf(nftID) == msg.sender, "msg.sender is not nft owner");
        hashmasks.transferFrom(msg.sender, address(this), nftID);

        // move NFT into NFTX pool
        hashmasks.approve(address(nftx), nftID);
        uint256[] memory list = new uint256[](1);
        list[0] = nftID;
        nftx.mint(VAULT_ID, list, 0);

        require(maskToken.balanceOf(address(this)) == ONE_MASK_TOKEN, "no-mask-token");

        address[] memory path = new address[](2);
        path[0] = address(maskToken);
        path[1] = address(weth);

        uint wantPrice = _currentFloor();
        // swap MASK token for WETH
        uint price = sushiRouter.swapExactTokensForTokens(ONE_MASK_TOKEN, rmul(wantPrice, tolerance), path, address(this), block.timestamp+1)[1];

        // transfer WETH to msg.sender
        payoutAmount = rmul(price, flipMaskRate);
        weth.transferFrom(address(this), msg.sender, payoutAmount);
    }

    // get a random mask with WETH
    function getRandomMask() public returns(uint nftID) {
        uint requiredAmount = rmul(_currentMaskTokenPrice(), getMaskRate);
        weth.transferFrom(msg.sender, address(this), requiredAmount);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(maskToken);

        // swap WETH for mask token
        sushiRouter.swapTokensForExactTokens(ONE_MASK_TOKEN, requiredAmount, path, address(this), block.timestamp+1);

        // redeem one NFT with mask token
        nftx.redeem(VAULT_ID, 1);

        nftID = hashmasks.tokenOfOwnerByIndex(address(this), 0);

        // send nft to msg.sender
        hashmasks.transferFrom(address(this), msg.sender, nftID);
    }

    function redeem() public {
        require(msg.sender == owner);
        weth.transferFrom(address(this), owner, weth.balanceOf(address(this)));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return 0x150b7a02;
    }
}