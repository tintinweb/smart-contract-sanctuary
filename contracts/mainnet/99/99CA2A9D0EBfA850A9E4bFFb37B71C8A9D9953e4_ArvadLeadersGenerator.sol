// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


contract ArvadLeadersGenerator {

  // Features for each department head referenced by "mod"
  uint[13] private _features = [
    21256282177277819339779345574010368,
    21337728762192110881255863649043712,
    21419492192056908729568701200736768,
    125345925175868027655275880363599360,
    20770772021568407366968296219875584,
    21581117662928525947566169494918400,
    21662564194650966869714541605825024,
    146358501559100786020293338380372224,
    21095290551048391492938831998488832,
    1055636066354277736373742666255616,
    21906270027380399681161878166318592,
    1217578416026619357196409863407872,
    167451890605234394112679180391952896
  ];

  /**
   * @dev No seed required for leaders generation, noop
   */
  function setSeed(bytes32) external pure {
    require(false, "ArvadLeadersGenerator: seed not required");
  }

  /**
   * @dev Returns the features for the specific crew member
   * @param _mod Number from 1 - 13 signifying which department head
   */
  function getFeatures(uint, uint _mod) public view returns (uint) {
    return _features[_mod - 1];
  }
}