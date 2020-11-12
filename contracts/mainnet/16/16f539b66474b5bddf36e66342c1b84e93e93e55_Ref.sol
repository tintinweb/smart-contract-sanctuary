pragma solidity ^0.5.0;

contract Ref {

    mapping(address => address) public referrer;
    mapping(address => uint) public score;
    mapping(address => address[]) public referrerArray;
    mapping(address => bool) public admin;

    modifier onlyAdmin() {
        require(admin[msg.sender], "You're not admin");
        _;
    }

    constructor() public {
        admin[msg.sender] = true;        
    }

    function scoreOf(address a) public view returns (uint) {
        return score[a];
    }

    function referrerNum(address a) public view returns (uint) {
        return referrerArray[a].length;
    }

    function get_referrer(address a) public view returns (address) {
        return referrer[a];
    }


    function set_admin(address a) onlyAdmin() external {
        admin[a] = true;
    }

    function set_referrer(address r) onlyAdmin() external {
        if (referrer[tx.origin] == address(0)) {
            referrer[tx.origin] = r;
            emit ReferrerSet(tx.origin, r);
            referrerArray[r].push(tx.origin);
        }
    }

    
    function add_score(uint d) onlyAdmin() external {
        score[referrer[tx.origin]] += d;
        emit ScoreAdded(tx.origin, referrer[tx.origin], d);
    }

    event ReferrerSet(address indexed origin, address indexed referrer);
    event ScoreAdded(address indexed origin, address indexed referrer, uint score);
}