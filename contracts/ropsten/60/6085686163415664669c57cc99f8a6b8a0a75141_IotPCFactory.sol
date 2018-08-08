pragma solidity ^0.4.0;


contract IotPC {
    
    struct approvement {
        uint commit_time;
        address pkd;
        bytes32 s;
    }
    bytes20 _uid;
    address _owner;
    uint _contract_start_time;
    uint public _days_till_expiration ;
    uint _num_of_updated_objects;
    uint _n;
    uint _delta_to_reveal;
    bytes32 _merkle_root;
    mapping (address => approvement) iot_devices;

    event Committed(address indexed pkd, address indexed pko, bytes32 s);
    event KeyRevealed(address indexed pko, bytes32 r);
    event Deposited(string msg, uint256 val);

    bytes32 REVEALED = 0x01;

    constructor (bytes32 merkle_root, bytes20 file_hash, uint days_till_expiration, address owner, uint delta_to_reveal, uint n ) public {
        _merkle_root = merkle_root;
        _owner = owner;
        _uid = file_hash;
        _contract_start_time = now;
        if (n > 0)
            _n = n;
        // delta to reveal has to be less than now
        _delta_to_reveal = delta_to_reveal;
        if (days_till_expiration >= 0)
            _days_till_expiration = days_till_expiration;
    }

    function () payable public {
        emit Deposited("Ether recieved", msg.value);
    }

    modifier only_owner() {
        require(msg.sender == _owner);
        _;
    }

    function withdraw_funds() only_owner public {
        require(now > _contract_start_time + _days_till_expiration * 1 days, &#39;Contract expiration not reached&#39;);
        _owner.transfer(address(this).balance);
    }

    function verify_signature(bytes32 hash,uint8 sig_v,bytes32 sig_r,bytes32 sig_s,address pko) public pure returns(bool){
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, hash);
        return ecrecover(prefixedHash,sig_v,sig_r,sig_s) == pko;
    }

    function commit(address pko, bytes32 pko_hash, bytes proof, bytes32 s, uint8 sig_v, bytes32 sig_r, bytes32 sig_s ) public {
        address pkd = msg.sender;
        require(now <= _contract_start_time + _days_till_expiration * 1 days, &#39;Contract expired&#39;);
        require(validate_pko(pko, pko_hash, proof), &#39;Invalid Merkle proof&#39;);
        require(iot_devices[pko].s != REVEALED, &#39;Key already revealed for this IoT&#39;);
        require(iot_devices[pko].pkd == 0 || (now - iot_devices[pko].commit_time) > _delta_to_reveal, &#39;Within reveal time window of another distributor&#39;);
        bytes32 hash = keccak256(_uid, s);
        require(verify_signature(hash, sig_v, sig_r, sig_s, pko), &#39;Invalid signature&#39;);
        iot_devices[pko].commit_time = now;
        iot_devices[pko].pkd = pkd;
        iot_devices[pko].s = s;
        emit Committed(pkd, pko, s);
    }

    function reveal(bytes32 r, address pko) public {
        address pkd = msg.sender;
        require(now <= _contract_start_time + _days_till_expiration * 1 days, &#39;Contract expired&#39;);
        require(iot_devices[pko].s != REVEALED && iot_devices[pko].pkd == pkd && pkd != 0, &#39;Key already revealed for this IoT or committed by another distributor&#39;);
        require(iot_devices[pko].s == sha256(r), &#39;Invalid key (not SHA256 preimage)&#39;);
        require(now - iot_devices[pko].commit_time <= _delta_to_reveal, &#39;Not within reveal time window&#39;);
        iot_devices[pko].s = REVEALED;
        uint delta = _n - _num_of_updated_objects;
        if (delta > 0) {
            uint amount_to_transfer = (address(this).balance / delta);
            pkd.transfer(amount_to_transfer);
        }
        _num_of_updated_objects = _num_of_updated_objects + 1;
        emit KeyRevealed(pko, r);
    }

    function validate_pko(address pko, bytes32 pko_hash, bytes proof) public returns (bool) {
        bytes32 curr_pko_hash = keccak256(pko);
        bytes32 el;
        bytes32 h = pko_hash;

        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                el := mload(add(proof, i))
            }

            if (h < el) {
                h = keccak256(h, el);
            } else {
                h = keccak256(el, h);
            }
        }

        return h == _merkle_root;
    }
}

contract IotPCFactory {

    event ContractPublished(bytes32 merkle_root, bytes20 package_info_hash, address contract_creator,address contract_address,bytes20 filehash, uint days_till_expiration);

    //maps every vendor to its list of contracts
    mapping(address => address[]) contracts;

    function createContract(bytes32 merkle_root, bytes20 package_info_hash, bytes20 filehash, uint days_till_expiration, uint delta_to_reveal, uint n) payable  public   {
       address newContractAddress = new IotPC(merkle_root,filehash,days_till_expiration,msg.sender, delta_to_reveal, n);
       contracts[msg.sender].push(newContractAddress);
       newContractAddress.transfer(msg.value);
       emit ContractPublished(merkle_root, package_info_hash, msg.sender,newContractAddress, filehash, days_till_expiration);
    }
}