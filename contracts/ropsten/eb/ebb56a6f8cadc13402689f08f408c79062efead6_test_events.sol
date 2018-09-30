pragma solidity ^0.4.0;

contract test_events{
    
    event write_logs(string _log,string _extra);
    
    function create_event(string _log)public  constant returns (bool) {
        emit write_logs(_log, &#39;extra&#39;);
        return true;
    }
    
}