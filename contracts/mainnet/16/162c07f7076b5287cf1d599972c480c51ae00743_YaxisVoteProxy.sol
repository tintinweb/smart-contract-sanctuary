pragma solidity ^0.6.12;


interface IVoteProxy {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _voter) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
contract YaxisVoteProxy {
    IVoteProxy public voteProxy;
    address public governance;
    constructor() public {
        governance = msg.sender;
    }

    function name() external pure returns (string memory) {
        return "YAXIS Vote Power";
    }

    function symbol() external pure returns (string memory) {
        return "YAX VP";
    }

    function decimals() external view returns (uint8) {
        return voteProxy.decimals();
    }

    function totalSupply() external view returns (uint256) {
        return voteProxy.totalSupply();
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return voteProxy.balanceOf(_voter);
    }

    function setVoteProxy(IVoteProxy _voteProxy) external {
        require(msg.sender == governance, "!governance");
        voteProxy = _voteProxy;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }



    /**
 * This function allows governance to take unsupported tokens out of the contract.
 * This is in an effort to make someone whole, should they seriously mess up.
 * There is no guarantee governance will vote to return these.
 * It also allows for removal of airdropped tokens.
 */
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}