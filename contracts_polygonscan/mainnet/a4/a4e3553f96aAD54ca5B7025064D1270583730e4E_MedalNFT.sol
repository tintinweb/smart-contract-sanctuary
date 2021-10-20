pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ERC721Base.sol";
import "./SafeMath.sol";

contract MedalNFT is ERC721Base {
    using SafeMath for uint256;

    event CreateMedalNFT(address owner, string name, string symbol);

    function __MedalNFT_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI) external initializer {
        _setBaseURI(baseURI);
        __ERC721Lazy_init_unchained();
        __RoyaltiesV2Upgradeable_init_unchained();
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Mint721Validator_init_unchained();
        __HasContractURI_init_unchained(contractURI);
        __ERC721_init_unchained(_name, _symbol);
        emit CreateMedalNFT(_msgSender(), _name, _symbol);
    }
    uint256[50] private __gap;


    struct MedalLockPoint {
        uint256                    unlock_time;     //unlock_time => points;
        uint256                    points;          //timestamp_keys
    }
    
    mapping(uint256 => uint256)                                 public contributions;  //tokenId => contribution
    mapping(uint256 => mapping(address => MedalLockPoint[]))    public alllockpoints;  //tokenId => tokenaddr => lockPoints
    mapping(uint256 => mapping(address => uint256))             public loyaltypoints;  //tokenId => tokenaddr => loyaltypoints
    

    event AddContributions(uint256 tokenId, uint256 value, uint256 point_type, uint256 lockindex, uint releasetime);

    function add_loyaltypoints (uint256 tokenId, address token_addr, uint points) public {
        require(isApprovedForAll(owner(), _msgSender()), "operator is not Approved");
        require(_exists(tokenId), "tokenId is not existed");
        loyaltypoints[tokenId][token_addr] = loyaltypoints[tokenId][token_addr].add(points);
    }

    function clear_points(uint256 tokenId, address token_addr) public {
        require(isApprovedForAll(owner(), _msgSender()), "operator is not Approved");
        require(_exists(tokenId), "tokenId is not existed");
        loyaltypoints[tokenId][token_addr] = 0;
    }

    function getMedal_lockpoints(uint256 tokenId, address token_addr) public view returns(MedalLockPoint[] memory) {
        require(_exists(tokenId), "tokenId is not existed");
        return alllockpoints[tokenId][token_addr];
    }

    function getMedal_loyaltypoints(uint256 tokenId, address token_addr) public view returns(uint256) {
        require(_exists(tokenId), "tokenId is not existed");
        return loyaltypoints[tokenId][token_addr];
    }

    function addContributions(uint256 tokenId, address token_addr, uint256 value, uint256 point_type, uint256 lockindex, uint releasetime) public { //authrized_address
        require(isApprovedForAll(owner(), _msgSender()), "operator is not Approved");
        require(_exists(tokenId), "addContributions: tokenId is not existed");
        require(point_type < 3, "addContributions: point_type incorrect");

        uint cur_contributions = contributions[tokenId];
        if (point_type == 0) { //free points
            loyaltypoints[tokenId][token_addr] = loyaltypoints[tokenId][token_addr].add(value);
            //attr.contribution = attr.contribution.add(value);
            contributions[tokenId] = cur_contributions.add(value);
        }
        else if (point_type == 1) {  //new lock points
            require(releasetime > block.timestamp, "addContributions: releasetime must be gt block time stamp");
            MedalLockPoint[] storage array = alllockpoints[tokenId][token_addr];
            array.push(MedalLockPoint(releasetime,value));
            //attr.contribution = attr.contribution.add(value);
            contributions[tokenId] = cur_contributions.add(value);
        }
        else if (point_type == 2) {
            MedalLockPoint[] storage array = alllockpoints[tokenId][token_addr];
            require(lockindex < array.length, 'lockindex is out range of lockPoints[]');
            array[lockindex].points = array[lockindex].points.add(value);
            //attr.contribution = attr.contribution.add(value);
            contributions[tokenId] = cur_contributions.add(value);
        }
        // emit return true;
        emit AddContributions(tokenId, value, point_type, lockindex, releasetime);
    }

    function release_locked_points(uint256 tokenId, address token_addr) public{
        require(_exists(tokenId), "tokenId is not existed");
        MedalLockPoint[] storage array = alllockpoints[tokenId][token_addr];
        uint256 unlock_v = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].unlock_time != 0 && array[i].unlock_time < block.timestamp) {
                unlock_v = unlock_v.add(array[i].points);
                delete array[i];
            }
        }
        uint256 lp = loyaltypoints[tokenId][token_addr];
        loyaltypoints[tokenId][token_addr] = lp.add(unlock_v);
    }
}