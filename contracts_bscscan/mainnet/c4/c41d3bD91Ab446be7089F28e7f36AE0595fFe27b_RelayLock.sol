//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IERC20.sol";

interface IRelayLock {
    function lock(uint256 destination, bytes calldata receiver) external payable;

    event Lock(uint256 indexed destination, bytes receiver, uint256 amount);
}
interface WNative {
     function deposit() external payable;

     function withdraw(uint wad) external;
     
     function approve(address spender, uint256 amount) external returns (bool);
}
interface V2Router {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

/// @title RelayLock
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract RelayLock is IRelayLock {

    address public owner;
    WNative public wnative;
    V2Router public router;
    IERC20 public gton;

    constructor (WNative _wnative, V2Router _router, IERC20 _gton) {
        owner = msg.sender;
        wnative = _wnative;
        router = _router;
        gton = _gton;
    }

    function lock(uint256 destination, bytes calldata receiver) external payable override {
        // TODO: transfer native
        // TODO: wrap native to erc20
        wnative.deposit{value: msg.value}();
        wnative.approve(address(router), msg.value);
        // TODO: swap for gton on dex
        address[] memory path = new address[](2);
        path[0] = address(wnative);
        path[1] = address(gton);
        uint[] memory amounts = router.swapExactTokensForTokens(msg.value, 0, path, address(this), block.timestamp+3600);
        // TODO: throw event
        emit Lock(destination, receiver, amounts[0]);
    }
    
    function reclaimERC20(IERC20 token) public {
        require(msg.sender == owner, "");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function reclaimNative(uint256 amount) public {
        require(msg.sender == owner, "");
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}