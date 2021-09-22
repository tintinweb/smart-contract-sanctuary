// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NativeMetaTransaction.sol";
import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SoccerDogeClub is
    ERC1155,
    ERC1155Holder,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;
    string constant NAME = "Poly Doge Club";
    string constant SYMBOL = "PDC";
    string constant _CONTRACT = "ERC1155";
    uint256 constant MAX_TOTAL_SUPPLY = 10000;
    uint256 constant MAX_NUM_PER_TOKEN = 1;
    uint256 constant batchCount = 500;
    uint256 constant price = 59000000000000000; // 0.059 ETH;
    uint256 public currentID = 1;
    string constant URI_BASE = "https://soccerdogeclubnft.s3.us-west-1.amazonaws.com/metadatas/sdc-metadata-";
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 private constant INTERFACE_SIGNATURE_URI = 0x0e89341c;

    constructor() ERC1155(URI_BASE) {
        _initializeEIP712(NAME);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        if (
            interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            interfaceId == INTERFACE_SIGNATURE_ERC1155 ||
            interfaceId == INTERFACE_SIGNATURE_URI
        ) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 _tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return _getUri(_tokenId);
    }

    function _getUri(uint256 _tokenId) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(URI_BASE, Strings.toString(_tokenId), ".json")
            );
    }

  
    receive() external payable {}

    fallback() external payable {}

    function withdraw() 
        public 
        onlyOwner 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function mintPayable(uint256 _customBatchCount) 
        external 
        payable 
    {
        require(_customBatchCount > 0, "count should be more than one");
        require(
            price.mul(_customBatchCount) <= msg.value,
            "Sorry, sending incorrect eth value"
        );

        _batchMint(msg.sender, _customBatchCount);
    }
    
    function mint(address _to, uint256 _customBatchCount)
        external
        onlyOwner
    {
        if (_customBatchCount <= 0) 
            _customBatchCount = batchCount;
        
        _batchMint(_to, _customBatchCount);
    }

    function _batchMint(
        address _to,
        uint256 num
    ) private {
        
        uint256 i = 0;
        uint256 range = num + currentID;
        require(range <= MAX_TOTAL_SUPPLY, "Sorry, Request More than TotalSupply, Please Change Number");
        uint256[] memory ids = new uint256[](num);
        uint256[] memory amounts = new uint256[](num);
        for (; currentID < range; currentID++) {
            ids[i] = currentID;
            amounts[i] = MAX_NUM_PER_TOKEN;
            require(_balances[currentID][_to] == 0, "Cannot mint existed token id");
            ++i;
        }
        super._mintBatch(_to, ids, amounts, "");
    }

    function burnBatch(address _account, uint256[] memory _ids)
        external
        onlyOwner
    {
        super._burnBatch(_account, _ids, _getAmountArray(_ids.length));
    }
    
    function transferBatch(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        super.safeBatchTransferFrom(from, to, ids, amounts, "");
    }
    
    function _getAmountArray(uint256 arrayLen)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory _amounts = new uint256[](arrayLen);
        for (uint256 i = 0; i < arrayLen; i++) {
            _amounts[i] = MAX_NUM_PER_TOKEN;
        }
        return _amounts;
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    function factorySchemaName() external pure returns (string memory) {
        return _CONTRACT;
    }

    function totalSupply() external pure returns (uint256) {
        return MAX_TOTAL_SUPPLY;
    }
}