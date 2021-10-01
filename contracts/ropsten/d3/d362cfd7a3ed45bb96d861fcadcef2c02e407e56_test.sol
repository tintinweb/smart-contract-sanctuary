/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity ^0.6.0;

contract test{
    
    function getPropsoalsData() public pure returns(string memory test){
       test = '[{"title":"Governance Upgrade","startDate":"8/20/2021","endDate":"8/30/2021","quorum":"30%","status":false,"class":1,"nonce":1,"vote":"false","proposalAddress":"0xASDSWEWQECSsdasaSDSDDFDFDF","detail":"test "},{"title":"Governance Upgrade","startDate":"8/20/2021","endDate":"8/30/2021","quorum":"30%","status":true,"class":1,"nonce":1,"vote":"false","proposalAddress":"0xASDSWEWQECSsdasaSDSDDFDFDFSFDSFDSFDSFWQEWQE"},{"title":"Governance Upgrade","startDate":"8/20/2021","endDate":"8/30/2021","quorum":"30%","status":false,"class":1,"nonce":1,"vote":"false","proposalAddress":"0xASDSWEWQECSsdasaSDSDDFDFDF","detail":"1111"},{"title":"Governance Upgrade","startDate":"8/20/2021","endDate":"8/30/2021","quorum":"30%","status":true,"class":1,"nonce":1,"vote":"false","proposalAddress":"0xASDSWEWQECSsdasaSDSDDFDFDFSFDSFDSFDSFWQEWQE","detail":"23534dfgdf"}]';
        return test;
    }
    
    
    function getOutputData() public pure  returns(string memory test2){
         test2 = '[{"nonce":1,"eta":"20-12-2021","progress":20,"sash":424412.121321,"usd":45134.4454},{"nonce":2,"eta":"20-2-2022","progress":20,"sash":424412.121321,"usd":45134.4454},{"nonce":4,"eta":"20-2-2022","progress":20,"sash":42912.121321,"usd":45134.4454},{"nonce":6,"eta":"20-5-2022","progress":20,"sash":784412.121321,"usd":45134.4454},{"nonce":7,"eta":"20-8-2022","progress":20,"sash":478975412.12167,"usd":67134.445564}]';
        return test2;
    }
    
}