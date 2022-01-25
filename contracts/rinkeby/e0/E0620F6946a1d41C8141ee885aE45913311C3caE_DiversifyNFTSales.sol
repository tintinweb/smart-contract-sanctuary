//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IDiversifyNFT {
    function mint(address, string memory) external;
}

contract DiversifyNFTSales {
    address public team;
    address public pendingTeam;

    address public diversifyNFT;

    address public withdrawer;
    uint256 public fee; //fee in terms of ETH, in wei

    uint256 public mintLimit;

    mapping(uint256 => string) public tokenURIs; // intiial tokenURIs added
    mapping(uint256 => bool) public usedTokenURIs; // used tokenURIs to prevent double mint

    uint256 public tokenURICount;

    event ChangeTeam(address _team);
    event AcceptTeam(address _team);
    event ChangeFee(uint256 _fee);

    modifier onlyTeam() {
        require(msg.sender == team, "not allowed");
        _;
    }

    modifier onlyTeamOrWithdrawer() {
        require(msg.sender == team || msg.sender == withdrawer, "not allowed");
        _;
    }

    constructor(
        address _team,
        uint256 _fee,
        address _withdrawer,
        address _diversifyNFT
    ) {
        withdrawer = _withdrawer;
        fee = _fee;
        team = _team;
        diversifyNFT = _diversifyNFT;
    }

    /// @notice Takes the {fee} and mints NFT based on tokenID provided
    /// @param _user Address where the NFT should be minted
    /// @param _tokenId TokenID of the NFT to be minted
    function mint(address _user, uint256 _tokenId) external payable {
        require(mintLimit + 1 <= mintLimit, "cannot mint more");
        // check if the NFT with the tokenID is already minted
        require(!usedTokenURIs[_tokenId], "already minted");
        // check if the contract received fee
        require(msg.value >= fee, "underpriced");
        // mint the NFT
        IDiversifyNFT(diversifyNFT).mint(_user, tokenURIs[_tokenId]);
    }

    /// @notice add initial token URIs (should be called by team)
    /// @dev each tokenURI will be stored incrementally and same id will be used for minting
    /// @param _tokenURIs array of tokenURIs
    function addInitialURIs(string[] memory _tokenURIs) external onlyTeam {
        tokenURICount += 1;
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            tokenURIs[tokenURICount] = _tokenURIs[i];
        }
    }

    /// @notice Withdraw the accumulated ETH to address
    /// @param _to where the funds should be sent
    function withdraw(address payable _to) external onlyTeamOrWithdrawer {
        _to.transfer(address(this).balance);
    }

    /// @notice Change minting fee
    function changeFee(uint256 _fee) external onlyTeam {
        fee = _fee;
        emit ChangeFee(_fee);
    }

    /// @notice Change withdraw permissions (only Team)
    /// @param _withdrawer New withdaw address
    function changeWithdrawer(address _withdrawer) external onlyTeam {
        withdrawer = _withdrawer;
    }

    /// @notice fallback receive function which keeps ETH in the contract itself
    receive() external payable {}

    /// @notice fallback function which keeps ETH in the contract itself
    fallback() external payable {}

    /// @notice Change admin address
    /// @param _team Address of the new admmin
    function changeTeam(address _team) external onlyTeam {
        pendingTeam = _team;
        emit ChangeTeam(_team);
    }

    /// @notice New admin needs to accept that he is new admin
    /// @dev should be called by the address set in changeTeam function.
    function acceptTeam() external {
        require(msg.sender == pendingTeam, "invalid");
        team = pendingTeam;
        pendingTeam = address(0);
        emit AcceptTeam(team);
    }
}