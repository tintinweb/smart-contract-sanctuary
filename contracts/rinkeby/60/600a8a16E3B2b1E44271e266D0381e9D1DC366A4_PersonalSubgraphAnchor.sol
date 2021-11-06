// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract PersonalSubgraphAnchor {
    event AddERC20(address user, address token);
    event AddERC20Sender(address _governance);
    event AddERC721(address _sushi);
    event AddERC721Sender(uint256 _fee);

    function addERC20Sender(address _token) external {
        _addERC20(msg.sender, _token);
    }
    function addERC20(address _user, address _token) external {
        _addERC20(_user, _token);
    }
    function _addERC20(address _user, address _token) internal {
        emit AddERC20(_user, _token);
    }
}


// contract PersonalSubgraphRegistry {
// 	ICuration curation = ICuration(0xTODO);

// 	function _onlySubgraphOwner(bytes32 subgraphID) internal {
// 		require(curation.owner(subgraphID) == msg.sender, "PSR: !owner");
// 	}

// 	// TODO - concept of personalSubgraph, where only msg.sender can do
//   // AND another wher eyou combine msg.sender and any address
//   // The subgraphs will look almost the exact same
// 	// need to think about it a bit deeper `

// 	function addToken(bytes32 subgraphID, addresses[] token, address user) external {
// 		_onlySubgraphOwner(subgraphID);	
// 		for (uint256 i = 0; i < addresses.lenght; i++){
// 			emit TokenAdded(subgraphID, addresses[i], user);
// 		}
// 	}
// }