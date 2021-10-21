/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

pragma experimental ABIEncoderV2;





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}




contract ERC20View {
    
    struct Info {
        string name;
        string symbol;
        uint256 decimals;
        uint256 totalSupply;
        uint256 userBalance;
    }
    
    function batchInfo(address[] memory _tokens, address _user) external view returns (Info[] memory tokenInfo) {
        uint256 tokensLength = _tokens.length;
        tokenInfo = new Info[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20 token = IERC20(_tokens[i]);
            tokenInfo[i] = Info(
                token.name(),
                token.symbol(),
                token.decimals(),
                token.totalSupply(),
                token.balanceOf(_user)
            );
        }
    }
}