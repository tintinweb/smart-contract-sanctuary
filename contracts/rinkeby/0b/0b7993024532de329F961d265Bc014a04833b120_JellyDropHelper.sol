pragma solidity 0.8.6;

import "IERC20.sol";
import "IMerkleList.sol";
import "IJellyFactory.sol";
import "IJellyDrop.sol";
import "DocumentHelper.sol";

contract JellyDropHelper is DocumentHelper {
    struct TokenInfo {
        address addr;
        string name;
        string symbol;
        uint256 decimals;
    }

    struct AirdropInfo {
        address airdrop;
        string merkleURI;
        uint256 rewardsPaid;
        TokenInfo rewardToken;
        RewardInfo rewardInfo;
        Document[] documents;
    }

    address owner;
    IJellyFactory jellyFactory;
    bytes32 public constant AIRDROP_ID = keccak256("JELLY_DROP");

    constructor(
        address _jellyFactory
    )
    {
        owner = msg.sender;
        setContracts(_jellyFactory);
    }

    function setContracts(address _jellyFactory) public {
        require(msg.sender == owner);
        jellyFactory = IJellyFactory(_jellyFactory);
    }

    function getTokenInfo(address _address)
        public
        view
        returns (TokenInfo memory)
    {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.addr = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        info.decimals = token.decimals();

        return info;
    }


    function getAirdropInfo(address _airdropAddress)
        public
        view
        returns (AirdropInfo memory airdropInfo)
    {
        IJellyDrop airdrop = IJellyDrop(_airdropAddress);
        IMerkleList list = IMerkleList(airdrop.list());
        airdropInfo.airdrop = _airdropAddress;
        airdropInfo.merkleURI = list.currentMerkleURI();
        airdropInfo.rewardToken = getTokenInfo(airdrop.rewardsToken());
        airdropInfo.rewardsPaid = airdrop.rewardsPaid();
        airdropInfo.rewardInfo = airdrop.rewardInfo();
        airdropInfo.documents = getDocuments(_airdropAddress);
    }

    function getAirdrops() public view returns (AirdropInfo[] memory) {
        address[] memory contracts = jellyFactory.getContractsByTemplateId(AIRDROP_ID);
        uint256 size = contracts.length;
        AirdropInfo[] memory airdrops = new AirdropInfo[](size);

        for (uint256 i = 0; i < size; i++) {
            airdrops[i] = getAirdropInfo(contracts[i]);
        }
        return airdrops;
    }

}

pragma solidity 0.8.6;

interface IERC20 {

    /// @notice ERC20 Functions 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}

pragma solidity 0.8.6;

interface IMerkleList {
    function tokensClaimable(uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) external view returns (bool);
    function tokensClaimable(bytes32 _merkleRoot, uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) external view returns (uint256);
    function currentMerkleURI() external view returns (string memory);

    function initMerkleList(address accessControl) external ;

}

pragma solidity 0.8.6;

interface IJellyFactory {

    function deployContract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract);
    function createContract(
        bytes32 _templateId,
        address _token,
        uint256 _tokenSupply,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract);
    function getContracts() external view returns (address[] memory);
    function getContractsByTemplateId(bytes32 _templateId) external view returns (address[] memory);
    function getContractTemplate(bytes32 _templateId) external view returns (address);

}

pragma solidity 0.8.6;

struct RewardInfo {
    /// @notice Sets the token to be claimable or not (cannot claim if it set to false).
    bool tokensClaimable;
    /// @notice Epoch unix timestamp in seconds when the airdrop starts to decay
    uint48 startTimestamp;
    /// @notice Jelly streaming period
    uint32 streamDuration;
    /// @notice Jelly claim period, 0 for unlimited
    uint48 claimExpiry;
    /// @notice Reward multiplier
    uint128 multiplier;
}
interface IJellyDrop {
    function list() external view returns (address);
    function rewardsToken() external view returns (address);
    function rewardsPaid() external view returns (uint256);
    function rewardInfo() external view returns (RewardInfo memory);
}

pragma solidity 0.8.6;

import "IDocument.sol";

contract DocumentHelper {
    struct Document {
        string name;
        string data;
    }

    function getDocuments(address _contract)
        public
        view
        returns (Document[] memory)
    {
        IDocument document = IDocument(_contract);
        string[] memory documentNames = document.getAllDocuments();
        uint256 documentCount = documentNames.length;

        Document[] memory documents = new Document[](documentCount);

        for (uint256 i = 0; i < documentCount; i++) {
            string memory documentName = documentNames[i];
            (documents[i].data, ) = document.getDocument(documentName);
            documents[i].name = documentName;
        }
        return documents;
    }
}

pragma solidity 0.8.6;

interface IDocument {
    function getAllDocuments()
        external
        view
        returns (string[] memory);

    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256);

    // function getDocumentCount() external view returns (uint256);

    // function getDocumentName(uint256 index)
    //     external
    //     view
    //     returns (string memory);
}