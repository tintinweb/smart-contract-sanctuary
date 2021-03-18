/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity 0.8.0;
interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}
contract Test is IERC1155Receiver {
    
    address erc20Wrapper = 0x6ba2091f1f415867b02cCAD07876960e3aE926c2;
    
    function getValues() public pure returns(address[] memory items, uint[] memory ids, uint[] memory amounts) {
        items = new address[](5);
        ids = new uint[](5);
        amounts = new uint[](5);
        
        items[0] = 0xEDf7dE64832b6D0998fE7E7D556A38005B994565; //ieth
        items[1] = 0x25E4ac6a9ADba26eFb3aDE755aC33A7C85552F0f; //dai
        items[2] = 0xCE34847810703C5FD47b23327c1B8dAD6413B1A9; //usdc  
        items[3] = 0x0419B5C078CdF1cAC30051aE1a84E20b3642c9a3; //wbtc
        items[4] = 0x3f502581B0BA9359eF88647A87E9A0Bc17DBb855; //gil
        
        ids[0] = 11027808402393750762873608378930398077418220124669629658698890017122249518391;
        ids[1] = 216332248014699719760898559183495860534809800463;
        ids[2] = 1177223277217511966978286364924487525418516328873;
        ids[3] = 23409314531803405575641807346508451043436841379;
        ids[4] = 361453745463702030921681311513459337237932783701;
        
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;
        amounts[4] = 1;
    }
    
    function testTranserWithBatch(address receiver) external {
        (, uint[] memory ids, uint[] memory amounts) = getValues();
        IERC1155(erc20Wrapper).safeBatchTransferFrom(
            address(this),
            receiver,
            ids,
            amounts,
            new bytes(0)
        );
    }
    
    function testTransferWithoutBatch(address receiver) external {
        (address[] memory items,, uint[] memory amounts) = getValues();
        for(uint i = 0; i < items.length; i++)
            IERC20(items[i]).transfer(
                receiver,
                amounts[1]
            );
    }
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4) {
        return 0xf23a6e61;
    }
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4) {
        return 0xbc197c81;
    }
}
interface IERC1155 {
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}