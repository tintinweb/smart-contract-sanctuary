// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Counters.sol";
import "./ERC721.sol";
import "./IMintPasses.sol";

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract SpaceMonkeys is ERC721 {

    // Launch (when true its launched)
    bool private launched;

    // Pre Mint Launch (when true the pre mint is launched) gets automatically enabled once team has minted.
    bool private preMintLaunched;

    using Counters for Counters.Counter;
    using Strings for uint256;

    event NewSpaceMonkeyMinted(uint id);
    event Withdrawn(address _address, uint amount);
    
    // track token ID
    Counters.Counter private _tokenId;
    // track mint pass token ID
    uint16 private _mintPassTokenId = 11111;

    IMintPasses private SpaceMonkeysMintPassContract;
    IMintPasses private SpaceMonkeysPreMintPassContract;

    constructor() ERC721("Space Monkeys", "SPM") { }

    /**
     * @dev sets mint pass contract address
     */
    function setMintPassContractAddress(address _contractAddress) public onlyOwner {
        SpaceMonkeysMintPassContract = IMintPasses(_contractAddress);
    }

    /**
     * @dev sets pre mint pass contract address
     */
    function setPreMintPassContractAddress(address _contractAddress) public onlyOwner {
        SpaceMonkeysPreMintPassContract = IMintPasses(_contractAddress);
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
     * @dev Launch the project (toggles minting)
     */
    function launchToggle() public onlyOwner {
        launched = !launched;
    }

    /**
     * @dev getter function for Launch state
     */
    function isLaunched() external view returns(bool) {
        return launched;
    }

    /**
     * @dev getter function for Launch state
     */
    function isPreMintPhase() external view returns(bool) {
        return preMintLaunched;
    }

    function disableMintPassesSalesToggle() private onlyOwner {
        SpaceMonkeysMintPassContract.toggleDisableSale();
        SpaceMonkeysPreMintPassContract.toggleDisableSale();
    }

    /**
     * @dev premint for team
     * @dev 20 will be minted for the team
     * @notice the NFTs will be minted and sent to the callers address
     * @notice only the owner of the contract can call this function
     * @notice enables pre minting
     */
    function mintReserveSpaceMonkeys() public onlyOwner {
        require(!preMintLaunched, "Team Mint Has already happened");
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        _mintToken();
        preMintLaunched = true;
        SpaceMonkeysMintPassContract.toggleDisableSale();
        SpaceMonkeysPreMintPassContract.toggleDisableSale();
    }

    /**
     * @dev pre minting the token (the number of pre mint participants will be minted)
     * @dev For people who want to participate but aren't capable to particpate because of gas wars
     * @notice enabled once teamMint() is called
     * @notice only eligable people can pre minutes
     * @notice pre minting can only 
     */
    function preMintSpaceMonkeys() public payable {
        require(preMintLaunched, "Pre minting isn't yet avalible");
        require(!launched, "Pre mint phase is over!");
        require(SpaceMonkeysPreMintPassContract.balanceOf(msg.sender) == 1, "Address not eligable for a pre mint");
        require(msg.value >= 77700000000000000, "Ether value sent is not correct"); // price for 1: 0.0777 eth

        _mintToken();

        SpaceMonkeysPreMintPassContract._burnMintPass(msg.sender);
    }

    /**
     * @dev called by mint pass holders to claim their NFT
     */
    function claimNFT() public {
        require(launched, "Minting has not started yet");
        require(SpaceMonkeysMintPassContract.balanceOf(msg.sender) == 1, "You don't own a mint pass!");
        _safeMint(msg.sender, _mintPassTokenId);
        emit NewSpaceMonkeyMinted(_mintPassTokenId);
        _mintPassTokenId -= 1;
        SpaceMonkeysMintPassContract._burnMintPass(msg.sender);
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that at least 0.01 ether is paid before minting
     * @dev makes sure that no more than 5 tokens are minted at once
     * @param _tokenCount the ammount of tokens to mint
     */
    function mintSpaceMonkeys(uint _tokenCount) public payable {
        require(launched, "Minting has not yet started");
        require(_tokenCount <= 5, "Cannot mint more than 20 tokens at a time");
        require(_tokenCount != 0, "You have to mint at least 1 token");
        require(_tokenId.current() + _tokenCount < 11111 - SpaceMonkeysMintPassContract.getCurrentMintPassSupply(), "Purchace will exeed max supply of tokens");
        require(msg.value == 77700000000000000*_tokenCount, "Ether value sent is not correct"); // price for 1: 0.0777 eth

        if (_tokenCount == 1) {
            _mintToken();
        } else{
            if (_tokenCount == 2) {
                _mintToken();
                _mintToken();
            } else {
                if (_tokenCount == 3) {
                    _mintToken();
                    _mintToken();
                    _mintToken();
                } else {
                    if (_tokenCount == 4) {
                        _mintToken();
                        _mintToken();
                        _mintToken();
                        _mintToken();
                    } else {
                        _mintToken();
                        _mintToken();
                        _mintToken();
                        _mintToken();
                        _mintToken();
                    }
                }
            }
        }
    }

    function _mintToken() private {
        _safeMint(msg.sender, _tokenId.current());
        emit NewSpaceMonkeyMinted(_tokenId.current());
        _tokenId.increment();
    }

}