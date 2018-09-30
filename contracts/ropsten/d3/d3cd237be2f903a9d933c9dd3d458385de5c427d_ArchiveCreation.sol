pragma solidity ^0.4.17;

contract ArchiveCreation {
   struct Archive {
     string projectNameToken;
     string projectName;
   }

   mapping (bytes32 => Archive) registry;
   bytes32[] records;

   function signArchive(bytes32 hash, string projectNameToken, string projectName) public {
     registry[hash] = Archive(projectNameToken, projectName);
   }

   function getRecords() public view returns (bytes32[]) {
     return records;
   }

   function getRecordNameToken(bytes32 hash) public view returns (string) {
     return registry[hash].projectNameToken;
   }
}