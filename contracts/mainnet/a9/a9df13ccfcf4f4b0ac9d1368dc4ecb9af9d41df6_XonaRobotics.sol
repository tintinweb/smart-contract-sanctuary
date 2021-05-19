pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";

contract XonaRobotics is ERC721URIStorage {
    uint8 public constant version = 1;
    address public OWNER1;
    address public owner2 = 0x48122D8Fa6D9F24DD27906e4221b8d1beE16e006;
    uint public SMART_CONTRACT_RELEASE_BY_UNIXTIME;
    uint32 public constant MAX_ROBOTS = 1000000;
    string public base_url = "https://ipfs.xonalabs.com/ipfs/";
    string public json_ipfs_id = "QmWtVoyFgeKJLTFdnbzUPHDhQJmTjbyuf26oRxu2gANghJ";
    uint32 public robots_counter;
    address[] public free_phase_addresses;
    bool public project_paused = false;
    uint256 private FREE_CLAIM_10_DAYS_IN_SECONDS = 864000;
    uint256 public free_claim_end_timestamp;
    uint256 public phase1_fee = 0.000000000000000001 ether;
    uint256 public phase2_fee = 0.0016 ether;
    uint256 public phase3_fee = 0.0049 ether;


    constructor() ERC721("XonaRobotics", "XROB") {
        OWNER1 = msg.sender;
        SMART_CONTRACT_RELEASE_BY_UNIXTIME = block.timestamp;
        robots_counter = 0;
        free_claim_end_timestamp = FREE_CLAIM_10_DAYS_IN_SECONDS + SMART_CONTRACT_RELEASE_BY_UNIXTIME;
    }

    event SubscibePayments(
        uint32 indexed id,
        address indexed user,
        uint256 indexed date,
        uint256 amount
    );

    function contractURI() public view returns (string memory) {
        string memory url = string(abi.encodePacked(base_url, json_ipfs_id, "/",  "about", ".json"));
        return url; // should redirect or return the about.json
    }

    function create_robot() internal returns (uint32) {
        robots_counter++;
        uint32 new_item_id = robots_counter;
        string memory tokenuri = string(abi.encodePacked(base_url, json_ipfs_id, "/",  uint2str(new_item_id), ".json"));
        _safeMint(msg.sender, new_item_id);
        _setTokenURI(new_item_id, tokenuri);
        
        return new_item_id;
    }

    function change_OWNER2(address _newaddr) public is_owner {
        owner2 = _newaddr;
    }

    function change_BASE_URL(string memory _url) public is_owner {
        base_url = _url;
    }

    function change_IPFS_ID(string memory _ipfsid) public is_owner {
        json_ipfs_id = _ipfsid;
    }

    function suspend_project(bool _param) public is_owner {
        project_paused = _param;
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }

    function append_address_if_free_phase(address addr) internal {
        if (robots_counter < 10000) {
            free_phase_addresses.push(addr);
        }
    }
    
    function check_if_address_included_in_free_phase(address addr) internal view returns (bool) {
        for (uint16 i; i<free_phase_addresses.length; i++) {
            if (free_phase_addresses[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function change_PHASE1_FEE(uint256 _new) public is_owner {
        phase1_fee = _new;
    }
    
    function change_PHASE2_FEE(uint256 _new) public is_owner {
        phase2_fee = _new;
    }
    
    function change_PHASE3_FEE(uint256 _new) public is_owner {
        phase3_fee = _new;
    }

    function payout(address payable _addr) public is_owner {
        _addr.transfer(address(this).balance);
    }

    function check_the_mint_phase_fee() internal {
        if (robots_counter >= 0 && robots_counter < 10000 && free_claim_end_timestamp > block.timestamp) {
            require (msg.value >= phase1_fee, "The ether amount is not enough to buy a robot! Phase1 (FREE)");
            bool claim_status = check_if_address_included_in_free_phase(msg.sender);
            require (claim_status == false, "This address already minted a free robot! Phase1 (FREE)");
        }
        else if (robots_counter >= 0 && robots_counter < 190000) {
            require (msg.value >= phase2_fee, "The ether amount is not enough to buy a robot! Phase2");
        }
        else if (robots_counter >= 190000 && robots_counter < MAX_ROBOTS) {
            require (msg.value >= phase3_fee, "The ether amount is not enough to buy a robot! Phase3");
        }
        else {
            require (msg.value >= 999 ether, "This statement will be never reached :)");
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (_i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
            return string(bstr);
        }

    receive() external
    pause_project
    check_if_max_robots_count_not_reached
    payable {
        check_the_mint_phase_fee();
        append_address_if_free_phase(msg.sender);
        create_robot();
        emit SubscibePayments(robots_counter, msg.sender, block.timestamp, msg.value);
    }

    modifier check_if_max_robots_count_not_reached() {
        require(robots_counter < MAX_ROBOTS, "The XonaRobotics buy period ended! 1M robots count reached.");
        _;
    }

    modifier pause_project() {
        require (project_paused == false, "Project owners suspended the project, sorry for the inconvenience");
        _;
    }

    modifier is_owner() {
    require(msg.sender == OWNER1 || msg.sender == owner2, "Caller is not smart contract owner");
    _;
    }
}