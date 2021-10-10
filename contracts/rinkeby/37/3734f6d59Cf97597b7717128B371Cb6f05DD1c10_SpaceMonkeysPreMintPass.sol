// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Counters.sol";
import "./ERC721.sol";
import "./ISpaceMonkeys.sol";

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract SpaceMonkeysPreMintPass is ERC721 {

    using Counters for Counters.Counter;
    using Strings for uint256;

    // space monkeys contract address
    address private spaceMonkeysContractAddress;

    event NewPreMintPass(uint id);
    event Withdrawn(address _address, uint amount);
    
    // track token ID
    Counters.Counter private _tokenId;

    ISpaceMonkeys spaceMonkeysContract = ISpaceMonkeys(spaceMonkeysContractAddress);

    constructor() ERC721("Space Monkeys Pre Mint Pass", "SMPM") { }

    function setSpaceMonkeysContractAddress(address _contractAddress) public onlyOwner {
        spaceMonkeysContractAddress = _contractAddress;
    }

    /**
     * @dev withdraw contract balance to a wallet
     * @notice won't execute if it isn't the owner who is executing the command
     * @param _address the address to withdraw to
     */
    function withdraw(address payable _address) public onlyOwner {
        emit Withdrawn(_address, address(this).balance);
        _address.transfer(address(this).balance);
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that at least 0.01 ether is paid before minting
     */
    function buyMintPass() public payable {
        require(!spaceMonkeysContract.isPreMintPhase(), "Pre mint pass selling phase is over!");
        require(balanceOf(msg.sender) == 0, "Cannot buy more than one pre mint pass!");
        require(_tokenId.current() < 3111, "pre Mint pass sold out!");
        require(msg.value == 77700000000000000, "Ether value sent is not correct");

        _safeMint(msg.sender, _tokenId.current());
        emit NewPreMintPass(_tokenId.current());
        _tokenId.increment();
    }

    function getCurrentMintPassSupply() external view returns(uint) {
        return _tokenId.current();
    }

    function _burnMintPass(address _address) external {
        require(msg.sender == spaceMonkeysContractAddress, "This function can only be called by the Space Monkeys contract!");
        _burn(_ownerToMintPassId[_address]);
    }

}