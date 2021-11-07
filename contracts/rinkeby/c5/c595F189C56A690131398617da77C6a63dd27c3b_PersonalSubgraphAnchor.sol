// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @dev A general contract that lets users anchor data on chain
/// The data being anchored is a single ethereum address, with all the tokens
/// it wants to track. We also add the sender to the event. This way, everyone
/// can have their own view of an account. To have a shared view of a single account
/// does not make sense, as there is no way to come to consensus about what the most
/// useful view is. Other than, every single token.
contract PersonalSubgraphAnchor {
    event AddERC20(address indexed sender, address indexed user, address indexed token);
    function addERC20(address _token, address _user) external {
        emit AddERC20(msg.sender, _user, _token);
    }
    function addERC20s(address[] memory tokens, address _user) external {
		for (uint256 i = 0; i < tokens.length; i++){
            emit AddERC20(msg.sender, _user, tokens[i]);
		}
	}

    // Note - NFTs not part of POC
    // event AddERC721(address indexed sender, address indexed user, address indexed token);
    // event AddERC721Sender(address indexed sender, address indexed user, address indexed token);

    // Note - not in use for POC
    // event AddERC20Sender(address indexed sender, address indexed user, address indexed token);
    // function addERC20(address _token) external {
    //     emit AddERC20Sender(msg.sender, msg.sender, _token);
    // }
    // function addERC20s(address[] memory _tokens) external {
	// 	for (uint256 i = 0; i < _tokens.length; i++){
    //        emit AddERC20Sender(msg.sender, msg.sender, _tokens[i]);
	// 	}
	// }
}