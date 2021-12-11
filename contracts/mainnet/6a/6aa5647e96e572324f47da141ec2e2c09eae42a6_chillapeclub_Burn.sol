/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

}
contract chillapeclub_Burn{
    uint public token_Price = 0.03 ether;
    address token_address = 0x218FDc5b352F6560E3ee67DA8112fe663f38AcA1;                         
    address burn_address = 0x0000000000000000000000000000000000000100;
    address _owner;
    bool public pause_sale = false;
    constructor(){
        _owner = 0xF802516768A3462f3672b5d36AB2835d75363186;
    }

    function burn2(uint id1, uint id2) external payable {
        require(msg.value == token_Price, "incorrect ether amount");
        require(id1 != id2, "Both Id cant be same.");
        require(pause_sale == false, "Sale is Paused.");
        IERC721(token_address).transferFrom(msg.sender, burn_address, id1);
        IERC721(token_address).transferFrom(msg.sender, burn_address, id2);

    }
    function set_token_price(uint _price) external{
        require(msg.sender == _owner, "You are not the owner.");
        token_Price = _price;
    }
    function set_token_address(address _address) external{
        require(msg.sender == _owner, "You are not the owner.");
        token_address = _address;
    }
    function setPauseSale(bool temp) external {
        require(msg.sender == _owner, "You are not the owner.");
        pause_sale = temp;
    }
    function withdraw() external {
        require(msg.sender == _owner, "You are not the owner.");
        uint _balance = address(this).balance;
        payable(0xf8caBDFDca3BEf9B86Aff7eeF516E2b1884A710B).transfer(_balance * 12 / 100);
        payable(0x18C0B7B74a6731D8cc4dF912E3EfD99a16AE43E8).transfer(_balance * 10 / 100); 
        payable(0xeC0DaAe4d5DFd7c4eEf1D61D094134999798344A).transfer(_balance * 10 / 100); 
        payable(0x62d2d53A55b667f169af0652EA26a36DEA0d738E).transfer(_balance * 5 / 100);  
        payable(0x20a851E8CF45742AB755576d911300B9330A3D5A).transfer(_balance * 10 / 100); 
        payable(0x9EfA9A49DAbE821F259B655788837a95312718Db).transfer(_balance * 1 / 100);  
        payable(0xF802516768A3462f3672b5d36AB2835d75363186).transfer(_balance * 17 / 100); 
        payable(0x44920617711d625107604B4ffC73fD8110CA80fb).transfer(_balance * 35 / 100); 
    }
}