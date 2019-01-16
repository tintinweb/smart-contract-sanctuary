pragma solidity ^0.4.23;

contract signaturitContract {

    address proxy;
    address owner;

    mapping(string => string) _mapping_string;

    mapping(string => uint) _mapping_uint;

    mapping(string => address) _mapping_address;

    mapping(string => bool) _mapping_bool;

    modifier permissioned(){
      require(msg.sender == proxy);
      _;
    }


    struct _Event {
      string _id;
      string _ip;
      string _user_agent;
      string _event_type;
    }

    struct _File {
      string _id;
      string _name;
      string _hash;
    }

    struct _Document {
      string _id;
      string _signed_email;
      string _signer_name;
      _File _child_File;
      mapping(string => _Event) _events;
    }

    mapping(string => _Document) _Documents;

    constructor() public {
      proxy = msg.sender;
      _mapping_string[&#39;id&#39;] = &#39;id_value&#39;;
      _mapping_string[&#39;subject&#39;] = &#39;subject_value&#39;;
      _mapping_string[&#39;body&#39;] = &#39;body_value&#39;;
    }

    function set_owner(address ownerAdr) permissioned public {
      owner = ownerAdr;
    }

    function get_uint(string memory keyValue) permissioned public view returns(uint) {
        return _mapping_uint[keyValue];
    }

    function get_string(string memory keyValue) permissioned public view returns(string memory) {
        return _mapping_string[keyValue];
    }

    function get_bool(string memory keyValue) permissioned public view returns(bool) {
        return _mapping_bool[keyValue];
    }

    function get_address(string memory keyValue) permissioned public view returns(address) {
        return _mapping_address[keyValue];
    }

    function get_struct_Document(string memory keyValue) permissioned public view returns(string memory, string memory, string memory) {
        return (_Documents[keyValue]._id, _Documents[keyValue]._signed_email, _Documents[keyValue]._signer_name);
    }

    function get_struct_Document_File(string memory keyValue) permissioned public view returns(string memory, string memory, string memory) {
        return (_Documents[keyValue]._child_File._id, _Documents[keyValue]._child_File._name, _Documents[keyValue]._child_File._hash);
    }


    function get_struct_Document_events(string memory keyValue, string memory keyMapping) permissioned public view returns(string memory, string memory, string memory, string memory) {
      return (_Documents[keyValue]._events[keyMapping]._id, _Documents[keyValue]._events[keyMapping]._ip, _Documents[keyValue]._events[keyMapping]._user_agent, _Documents[keyValue]._events[keyMapping]._event_type);
    }


    function set_struct_Document(string memory id_value,string memory signed_email_value,string memory signer_name_value) permissioned public {
      _File memory tmpFile = _File({
        _id: &#39;&#39;,
        _name: &#39;&#39;,
        _hash: &#39;&#39;
      });

      _Document memory tmp = _Document({
        _id: id_value,
        _signed_email: signed_email_value,
        _signer_name: signer_name_value,
        _child_File: tmpFile
      });

      
      _Documents[id_value] = tmp;
      
    }

    function set_struct_Document_File(string memory parent_id, string memory id_value, string memory name_value, string memory hash_value) permissioned public {
      _Documents[parent_id]._child_File._id = id_value;
      _Documents[parent_id]._child_File._name = name_value;
      _Documents[parent_id]._child_File._hash = hash_value;
    }


    function set_struct_Document_events(string memory parent_id, string memory id_value, string memory ip_value, string memory user_agent_value, string memory event_type_value) permissioned public {
      _Event memory tmp_Event = _Event({
        _id: id_value,
        _ip: ip_value,
        _user_agent: user_agent_value,
        _event_type: event_type_value
      });

      
      _Documents[parent_id]._events[id_value] = tmp_Event;
      
    }

    function set_string(string memory keyType, string memory value) permissioned public {
      _mapping_string[keyType] = value;
    }

    function set_uint(string memory keyType, uint value) permissioned public {
      _mapping_uint[keyType] = value;
    }

    function set_address(string memory keyType, address value) permissioned public {
      _mapping_address[keyType] = value;
    }

    function set_bool(string memory keyType, bool value) permissioned public {
      _mapping_bool[keyType] = value;
    }

}