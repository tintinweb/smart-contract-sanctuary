//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITheCreepz.sol";


contract Extend {
  using Strings for uint256;

    constructor() public {
      //COLORS
      art._colors = ["#FF0000", "#FF8000", "#FFFF00", "#00FF00", "#00FF80", "#00FFFF", "#0080FF", "#0000FF", "#8000FF","#FF00FF","#FF0080","#171717",'#EBEBEB'];
      art._colors2 = ["#8D1E15", "#90501F", "#999832", "#61962F", "#469655", "#459798", "#1E4D94", "#001493","#451993","#8C2594","#8D204C","#454545","#E8E8E8"];
      //BG
      storeData(1,0,'Heart',"M280.2,171.3c28.9-32.2,33.3-83.3,9-120c-7.2-11-16.6-20-27.4-26.3c-10.8-6.3-22.8-9.7-35-10.1H224c-23.8,0-46.7,10.1-64,28.3C142.7,25.1,119.8,15,96,15c-0.9,0-1.9,0-2.8,0C81,15.3,69,18.7,58.2,25C47.4,31.3,38,40.3,30.8,51.3c-24.2,36.6-19.9,87.8,9,120L160,304.9L280.2,171.3z",'','');
      storeData(1,1,'Star',"M160,15l26.7,80.4l75.8-38l-38,75.8L305,160l-80.4,26.7l38,75.8l-75.8-38L160,305l-26.7-80.4l-75.8,38l38-75.8L15,160l80.4-26.7l-38-75.8l75.8,38L160,15z",'','');
      storeData(1,2,'Triangle',"M160,15l145,290H15L160,15z",'','');
      storeData(1,3,'Square',"M15,15h290v290H15V15z",'','');
      storeData(1,4,'Circle',"M160,15c80.1,0,145,64.9,145,145s-64.9,145-145,145S15,240.1,15,160S79.9,15,160,15z",'','');
      storeData(1,5,'Door',"M15,160C15,79.9,79.9,15,160,15l0,0c80.1,0,145,64.9,145,145v145H15V160z",'','');
      //BODY
      storeData(2,0,'Spike 1',"M72,320c48.7-18.9,76.6-66.8,88.1-115.5c11.1,48.4,39.6,97.1,87.9,115.5H72z","y1='204.5'","x='18' y='174.5' width='284' height='223.5'");
      storeData(2,1,'Spike 2',"M65.4,320c0.2-47.3-14.7-91.5-31.4-132.1c5.7-45.4,19.5-89.7,41.8-125.7c2.3-3.3,4.2-7.4,6.8-10.2c-2.6,8.3-5,16.6-6.4,25.4c-2.1,15.2-4.4,31-2.3,46.4c4.7,25,21.9,46.7,42.1,47.9c30.5,2.6,42.8-37.7,45.9-27.5c20.9,36.9,62.9,36.7,79.5-5.4c10.5-26.5,3.7-59.2-3.9-85.7c23.2,29.5,41.1,82.5,47.5,128c0.1,3,1.4,6.2,0.6,9c-12.8,27.5-22.2,56.7-27.5,88.1c-2.3,13.7-3.5,27.7-3.6,41.8H65.4z","y1='52'","x='0' y='22' width='360' height='376'");
      storeData(2,2,'Spike 3',"M7,320c3.7-21.8,36.7-81.8,58.5-87.4c-17.9-22.3-39.3-44-44.6-73.2c45.5,14.3,99.3,9.1,137.8-20.4c0.9-0.7,1.5-0.7,2.3,0c38.5,29.4,92.4,34.8,137.9,20.3c-5.6,29.1-26.5,50.9-44.6,73.1c22.5,6.8,54.4,64.7,58.5,87.6L7,320z","y1='138.5'","x='0' y='108.5' width='414' height='289.5'");
      storeData(2,3,'Spike 4',"M82.9,320C39,242,18,186.3,30.6,93.5c55.1,107.6,204.6,107.6,259.8,0.1c12.8,94.4-8.4,147.3-52.2,226.4H82.9z","y1='93.5' ","x='0.96' y='63.5' width='375.09' height='334.5'");
      storeData(2,4,'Spike 5',"M28.5,320c16.6-38.5,42.8-71.8,61.6-109.2c15.7-30.9-5.4-44.9-32.5-54.4c0-0.1,0-0.1,0-0.2c98.9-24.7,105.9-25.3,204.8,0.2c-16.9,6.3-41.2,16.6-37.6,38.5c2.9,15.9,12.4,29.5,20.4,43.3c16,26.9,33.7,53,46.2,81.8H28.5z","y1='137.5'","x='0.5' y='107.5' width='371' height='290.5'");
      storeData(2,5,'Spike 6',"M160,146.5c27.4.4,74.7-1.5,74.2-38,42.7,55.2,60.3,143.9,78.2,211.5H7.6c18-67.8,35.5-156.2,78.2-211.5-.5,36.6,46.8,38.4,74.2,38","y1='108.5'","x='0' y='79' width='412.8' height='319.5'");
      storeData(2,6,'Spike 7',"M315.1,320c-7.7-96.4-47.8-118-72.4-144.1,2.4,8.1-.6,75.2-18.1,52.9L160,151.4,95.4,228.8c-17.6,22.1-20.5-44.5-18.1-52.9C52.8,201.9,12.6,223.7,4.9,320","y1='151.4'","x='0.9' y='121.4' width='418.2' height='276.6'");
      storeData(2,7,'Spike 8',"M287.6,210c-4,6-7.8,12.1-12.9,17.5-4-13.8-9.8-26.5-15.9-39.4-3.9,3.9-6.9,8.4-10.4,12.7a295.3,295.3,0,0,0-18.1-40.6l-2,3.3c-7.5,13-17.3,23.8-30,31.8A154,154,0,0,1,160,212.7a154,154,0,0,1-38.3-17.4c-12.7-8-22.5-18.8-30-31.8l-2-3.3a295.3,295.3,0,0,0-18.1,40.6c-3.5-4.3-6.5-8.8-10.4-12.7-6.1,12.9-11.9,25.6-15.9,39.4-5.1-5.4-8.9-11.5-12.9-17.5,0,0-28.1,47.8-28.1,110H315.7C315.7,257.8,287.6,210,287.6,210Z","y1='160.2'","x='0.3' y='130.2' width='419.4' height='267.8'");
      storeData(2,8,'Round 1',"M109,320c7.7-20.8,29.4-41.9,52.9-41c22,1.5,41.8,21.1,49.1,41H109z","y1='279'","x='55' y='249' width='210' height='149'");
      storeData(2,9,'Round 2',"M64.5,320c12.8-65,35.7-134.8,94.9-171.5c60.3,34.3,83.1,106.9,96.1,171.5H64.5z","y1='148.5'","x='10.5' y='118.5' width='299' height='279.5'");
      storeData(2,10,'Round 3',"M24,320c1.9-52.5,9.2-216.4,56.6-229.4c28.7-3.5,64.6,60.5,79.6,88.9c16.2-29.9,64-118.7,94.9-78.9c36.1,56.3,37.1,149,41.4,219.4H24z","y1='90.5'","x='0' y='60.5' width='380.5' height='337.5'");
      storeData(2,11,'Round 4',"M293.5,265.1c-16.3-63-30.3-33.3-52-59.6-9.9-17.3-16-41.8-45.3-39.9-14.9,1-18.9-27-33.9-24.7-15.1-2.3-19.1,25.7-34,24.7C99,163.7,92.9,188.2,83,205.5c-21.7,26.3-35.6-3.4-52,59.6C26.6,281.6,0,280.9,4.3,320H320.2C324.5,280.9,297.9,281.6,293.5,265.1Z","y1='140.76'","x='0.8' y='110.7' width='424.8' height='287.2'");
      storeData(2,12,'Round 5',"M263.8,130.2c-87.2-34.8-28.6-54.1-48.4-74.5a.9.9,0,0,0-1.5.2c-2.2,4,6.2,7.1-4.4,24.3-11.3,25.6,10.6,49.4,30.1,63.4,16.4,14,4.1,44-9.2,56.3-20.9,18.9-53.4,7.9-70.4-11-17,18.9-49.5,29.9-70.4,11-12.4-11.8-20.5-32.3-15-49,8.6-13.3,25.2-19.4,32.3-34.2,8.9-14,8.4-31.2-.5-45.1-2.9-5.1-.7-10.2.2-15.4-1.8-3.8-4.2,1.8-5.1,3.6-5.5,14.8,12.4,26.1.1,42-10.5,15.3-29.3,20.8-45.3,28.4-.2.1-52.9,28.3-52.9,88.2,0,23.2,25.3,23.2,25.3,101.6H291.3c0-78.4,25.3-78.4,25.3-101.6C316.6,158.5,263.9,130.3,263.8,130.2Z","y1='54.9'","x='0.39' y='24.9' width='421.2' height='373.094'");
      //FACE
      storeData(3,0,'ANGIE',"M125.6,88.5c10.3,0,21.5,1.5,29,9.3c1.1,0.6,5.4,6.7,5.9,5.6c5.3-6,11.1-11.5,19.2-13.3c9.6-2,19.9-2.2,29.3,1.3c26,9.5,48.5,35.7,42.5,64.5c-3.3,16.6-15.2,27.5-30.1,34.4c-10.7,5.1-20.1,12.5-29.1,20.2c-10.2,8.6-17.5,19.8-24.2,31.2c-0.2,0.4-0.4,0.4-0.7,0.1c-4.3-3.5-6.6-8.5-7.2-14c-0.6,5.2-2.9,10.3-7,13.8c-0.6,0.5-0.6,0.5-1-0.2c-7.2-12.2-15.1-24.1-26.3-33c-8-6.2-16-12.7-25.1-17.3c-11.6-5.4-23.1-13-28.4-25c-8.3-17.4-4.2-39.1,8.4-53.5C92.4,100,107.9,89.4,125.6,88.5z","y1='88.5' y2='242'","x='14' y='58.5' width='292.5' height='261.5'");
      storeData(3,1,'CRAB',"M186.9,242h-0.2c-26.9-24.9-27.1-24.9-53.9,0h-0.2c-18-22.6-56.7-57.6-61.6-85.5c16-30.9,40.3-58.9,72.2-73.9c8.2-4.1,17.8-6.5,26.6-2.7c34.2,13.3,60.5,42.3,77.5,74.2c0.7,1.6,2.4,3.1,1.5,4.9c-1.7,5.2-4.1,10.2-6.8,15C227.1,199.2,205.9,219.9,186.9,242z","y1='78' y2='242'","x='17' y='48' width='286' height='272'");
      storeData(3,2,'SCRIM',"M157.1,83.5c53.8-1.6,81.7,41.4,72.7,91.7c-3.2,18.5-16.7,32.3-27.8,46.6c-7.6,9-12.4,19.8-18.5,29.7c-6.9,15.9-29,21.1-41.1,8c-8.8-9.4-13-22-20.8-32.2c-6.8-8.8-14.2-17.2-20.9-26.1c-12-15.7-13.7-35.9-11.3-55C90.5,110.7,122.6,83.9,157.1,83.5z","y1='83.5' y2='267'","x='34.5' y='53.5' width='251' height='291.5'");
      storeData(3,3,'SOPH',"M215.6,75.1c15.6,4.1,21.9,31.3,21.3,45.6c-0.3,17.1-10.2,31.5-18,46c-15.7,27.4-18.5,74.3-57,78.7c-40.2-0.1-44.5-49.3-59.5-77c-8.8-16.7-20.4-33.4-18.8-53.2c0.5-10.2,3.2-20.4,8.7-29.1c7.2-11.7,16.5-16.8,14.8,2c-1.6,16.8,12.4,34.9,29.3,23.4c8.5-5.8,10.6-16.7,17.9-23.5c5.6-5,12.8-0.6,15.9,5c3.5,5.7,6.5,11.9,11.5,16.6c12,12.2,30.8,1.3,30.8-14.5C213.8,89.6,209,73.7,215.6,75.1z","y1='75' y2='245.5'","x='29.5' y='45' width='261.5' height='278.5'");
      storeData(3,4,'SQUEL',"M161.4,267.5c-12.8-0.2-23.1-10.5-31.2-19.4c-4.7-8.9-4.7-20-10.8-28.3c-3.7-4.8-8.5-8.6-12.7-12.9c-5.2-12.5-7-26.8-10.9-39.8c-2.7-10.6-5.4-21.2-8.2-31.8c-1-5.9,8.9-10.6,12.7-14.3c29.4-19.7,68.1-25.6,100.7-10.2c9.3,3.8,30.5,13.9,32.5,24c-6.7,23.8-11.3,48.7-19.1,72c-7.2,6.8-15.3,13.3-17.9,23.4c-2,5.7-2.9,12-5.5,17.5C183.2,256.5,173.6,266,161.4,267.5z","y1='102' y2='267.5'","x='33.5' y='72' width='254' height='273.5'");
      storeData(3,5,'NIGHT',"M160,83c19.4,9,38.8,18.3,58.2,27.3c1.7,1.3-0.5,4.9,1.1,6.2c4.2,2.4,8.4,4.7,12.6,7.1c0.4,0.2,0.5,0.4,0.4,0.8c-0.2,2.1-2,5.3-1.3,7.1c1.2,1.2,9.6,5.3,8.4,6.3c-9.6,21.1-19.2,42.3-28.8,63.4c-2.4,3.5,0.2,7.4-2.7,9.8c-15.8,18.3-31.6,36.6-47.4,55c-11.3-10.5-22-25.5-33.1-37.5c-5.4-6.2-10.8-12.5-16.1-18.7c-0.9-1.5-0.2-3.6-0.4-5.4c-9.7-22.5-20.4-44.8-30.4-67.3c9.4-7,10-2.9,7.4-12.6c-0.2-0.7-0.2-0.7,0.5-1c4.2-2.3,8.3-4.7,12.5-7c1.1-1.2,0.3-3.4,0.5-5C119.1,100.5,140.9,92.9,160,83z","y1='83' y2='266'","x='26.5' y='53' width='267' height='291'");
      storeData(3,6,'ALLEN',"M161.3,244c-28.3,0.4-38.5-31.1-52.3-50.6c-17.7-26.8-25.4-63.7-8.8-92.8c6.5-10.9,16.3-25,30.1-25.5c22,0.2-23,29.9,16.3,33.5c10.3,0.5,43.3,3.6,45-9.8c-0.5-7.4-12.7-14.9-5.1-21.7c8-7.3,19.2,5.4,24.9,11c14.8,17,20.6,40.5,16.4,62.5c-2.2,20.6-13.5,38.5-24.7,55.4C193.1,222.2,182.5,242.9,161.3,244z","y1='75' y2='244'","x='37' y='45' width='246' height='277'");
      storeData(3,7,'TLIP',"M227.2,82.5c18.1,0.9,15.1,30.5,15.8,43.3c-0.5,32.3-18.9,98.9-57.6,101.6c-12.1,1.7-16.7-15.3-27.6-13c-7.7,3.1-11.8,13.1-21,12.8c-41.5,1-62.3-80.2-58.9-113.3c0.6-9.5,0.7-20.3,7.3-27.8c8.4-8.7,18.7,2,22,10.3c13.3,35,21.2,25.3,36.6-1.2c8.3-13.2,22.4-14.8,31.7-1.6c8.2,12,21.2,41,32.6,13.9C212.7,98.3,215.6,84.9,227.2,82.5z","y1='82.5' y2='227.5'","x='23.5' y='52.5' width='273.5' height='253'");
      storeData(3,8,'ELLY',"M158.4,73.5c59.7-2.2,49.9,105.2,82.3,143,8,14.4,18.6,27.2,29.4,40,7.6,15.1-18.9,14.7-28.2,9.4-32.4-14.3-35.9-40.5-28.4-2.2,0,6.3-6.7,11.5-13.6,10-16.6-3.8-24-20.8-38.6-27.5-11.9.3-26,25.3-40.4,27.4-8.3,2.3-15.8-5.4-14-12.7-.2-1.7,5.7-19.7,2.6-17.1-13.2,11.6-45.3,38.9-60.8,18.7-1.2-3.3,1.6-6.5,3.7-8.9C117.6,194.7,96.1,78.3,158.4,73.5Z","y1='70' y2='270.5'","x='5' y='40' width='310.5' height='308.5'");
      storeData(3,9,'DRAKE',"M99.2,78.5c15.5,10.1,48,32.6,61,9.2c13.4,24.1,45.7-0.3,61.4-8.9c11.3,9.3,15.8,23.5,16.9,36.9c-1,10.9-8.5,20.7-10.4,31.7c-9,50.6-18.9,63.2-55.9,101.7c-3.9,4-7.9,8-11.9,11.9c-2-1.7-3.9-3.7-5.8-5.6c-19.1-19.7-38.8-39.8-51.1-63.7c-6.5-16.1-6.7-33.9-12.7-50.2c-2-7.9-6.3-15.2-8.7-22.9C82.2,104.1,87,88.5,99.2,78.5z","y1='78.5' y2='261'","x='28' y='48.5' width='264.5' height='290.5'");
      storeData(3,10,'BIRDY',"M160,104.5c71.6,1.5,50.9-97.2,70.2-32.3c15.5,52.3-10.6,68,4.9,61.5c17.3-7.2,35.8-25.6,21.1,6.2c-9.1,21.5-15.9,50.2-35.6,64.5c-21.5,13.9-47.4,23-60.6,46.6c-13.2-23.5-39.1-32.6-60.6-46.6c-19.7-14.3-26.6-43.1-35.6-64.5c-14.6-31.7,3.6-13.5,21.1-6.2c11.4,5.4,1-7.5,0.8-12.8c-4.2-16.1,1.2-29,4.1-48.7C109.3,7.1,88.1,105.9,160,104.5z","y1='50' y2='251'","x='4.5' y='20' width='311' height='309'");
      storeData(3,11,'OTTO',"M178.2,88.1c17.2,29.9,45.8,36.7,51.5,89.5c0.4,1.5,0.9,1.8,1.7,0.1c4.5-8.7,3.8-19,1.4-28.2c-8.5-31.5-39.5-52.3-46.9-83.7c21.5,48.1,66.7,42.8,75.5,109.1c2.9,34.9-18.4,68.8-48,86.2c-3,2.5-6-2.2-8.6-3.5c-12.9-9-20.6-23-30.7-34.7c-8.9-10.5-22.8-7.2-30,3.3c-9.3,12.6-18.5,25.7-31.9,34.3c-1.2,0.8-2.5,2.1-3.9,1c-32-18.4-56.1-57.7-47.2-95c10.4-56.8,54.8-56.3,74-100.7C128.2,101,69.7,140.1,90.1,179c4.6-51.7,37.4-65.1,56.2-97.5c7-10.2,11.9-22.4,14.2-34C161.6,62.7,170.6,75.4,178.2,88.1","y1='47.5' y2='262'","x='5' y='17.5' width='310.5' height='322.5'");
      storeData(3,12,'BEETLE',"M221.8,219.9c-4.6,0.7-5.6-2.3-4.3-6.2c2.5-9.9-6.9-15.2-15.5-13.7c-14.7,2.4-26,14.9-41,16c-16.1,0.1-28.2-13.9-43.7-16.1c-24.2-0.5-9.8,18.6-16.4,20c-13.4,1-26.6-8.6-30.1-21.9c-6.1-29,21.7-51.1,36.4-72.6c13.2-16.2,25.1-33.4,34.5-52.2c5.9-10,5.6,6.9,6.4,10.7c1,8.3,5.3,26.7,16.7,18.9c6-6.1,6.4-15.9,7.7-24c0.7-19.6,8.1-0.4,11.9,6.1c5.4,9.7,11.7,18.8,18.4,27.6c16.7,24.4,43,45.5,47.7,76.2C250.9,204.8,237.8,219.3,221.8,219.9z","y1='70' y2='220'","x='16' y='40' width='288.5' height='258'");
      storeData(3,13,'LEAFY',"M161.6,237c-20.7,1-29.8-16.8-46.6-25.2c-22.4-9.9-29.6-40-32.3-62.4c-2.8-23-0.7-45.2,8.9-66.4c2.4-6.4,7.5-1.3,6.9,3.5c0.1,7.1-1.8,14-1.4,21.1c0,6.9,6.9,27.9,16.1,21.9c7.4-11.7,2.7-26.8,3.7-39.8c0.5-4.9,1-28.7,9-24.5c7.7,11.4,5.5,28.2,16.2,38.3c13.3,6.9,8.5-67.2,16.5-72.5c10.4-6.4,8,41.2,10.3,47.7c0.8,7.2,2,14.3,4.1,21.2c6,15,14.8-12.9,16.1-18.6c0.7-6.7,6.7-26.6,11.9-10.6c5.7,17.7-0.3,36.4,3.8,54.2c6.7,18.7,20.1-8.8,19-17.8c0.5-7.5-2-14.8-1.3-22.3c5.1-15.9,11.7,15.1,13.5,19.4c5.5,23.2,2.9,48.7-4.5,71.3c-5.4,20.5-19,31.1-34.8,42.2C185.4,226.4,177.3,236.6,161.6,237z","y1='30.5' y2='237.008'","x='27.5' y='0.5' width='265.5' height='314.508'");
      storeData(3,14,'FOX',"M228,99.1c25.2.4,40.7-5.2,20.9,25.6l-39.1,70.1c-2.3,3.7-6.7,5.4-10,8.1s-6.9,7.1-8.9,11.6c-5.8,11.8-12.4,23.3-18,35.2-.8,3.2-11.8,17.4-14.1,14.6-11.8-9.7-15.4-24.9-23.2-37.5-8.8-15.4-6.5-19.6-23.4-29.6-17.3-27-31.6-56.5-47.9-84.3-4.1-5.5-3.8-13.4,4.4-13.8,28.3-3.4,54.8,9.4,82.7,8.6a10.5,10.5,0,0,0,6.7-3.1c3.9-4,3.1,4.1,15.4,3.4C192,107.8,209.7,100.9,228,99.1Z","y1='94' y2='294'","x='0' y='45' width='348' height='308'");
      storeData(3,15,'ZELL',"M181.8,16c-19,24.2,19.3,91.8-21.8,101.4-41.1-8.6-2.8-77.5-21.8-101.4-10.3,64.7-80.7,90.4-65.6,119,11.1,23.9,28.3,36.7,40,59.8,8.3,15.5,27.5,40.1,47.4,47.2,20-7.1,39-31.7,47.3-47.2,11.8-23.1,29-35.9,40-59.8C262.6,106.4,192,80.7,181.8,16Z","y1='32' y2='258'","x='17' y='2' width='286.975' height='334'");
      storeData(3,16,'ROBIE',"M268.3,172.7a66.3,66.3,0,0,1-15.5-11.3c-37.6-34.3-56.9-82-64-131.4-12.1,19.7-6.3,14.6-10.4,36.5-1,16.4-8.5,38.5-18.2,38.1h-.4c-9.7.4-17.2-21.7-18.2-38.1-4.1-21.9,1.7-16.8-10.5-36.5-7,49.4-26.3,97.1-63.9,131.4a66.3,66.3,0,0,1-15.5,11.3c-8.7,6.9,18.6,10.2,22.9,12.5,28.9,8.4,59.1,21.6,73.4,49.5l12,.3,11.9-.3c14.4-27.9,44.6-41.1,73.4-49.5C249.7,182.9,277,179.6,268.3,172.7Z","y1='42.5' y2='247.5'","x='0' y='12.5' width='326.557' height='313'");
      storeData(3,17,'GOB',"M42.8,107.9c16.6,2.5,34.1,1.6,50.3,5.7,26.7,29.6,23.6,3.5,46-10.3a39,39,0,0,1,18.6-5.8,38.3,38.3,0,0,1,19.1,4.1c16.8,5.2,23.8,37.4,38.8,21.7,5.4-6.7,11.5-12.4,20.6-11.7,14-1.3,28.1-2.8,42.3-3.5,1.2-.1,2,.9,1.1,2-9.9,15.9-23.2,29.1-35.1,43.4s-20,28.8-31.9,41.6c-16.3,16.3-22.3,38.8-29.5,60.1-2,6.5-19.4,46.2-24.9,42-14.8-20-22.8-43.5-30.4-67.1a97.8,97.8,0,0,0-22-36.2C90.7,176.2,78.9,156,62.7,139.2c-2.4-3.2-31.7-34-19.9-31.1Z","y1='95.4' y2='295.5'","x='0' y='45' width='347.976' height='308.051'");
      storeData(3,18,'ZERO',"M235.8,165.3A75.8,75.8,0,1,1,160,89.4,75.8,75.8,0,0,1,235.8,165.3Z","y1='84' y2='235.6'","x='30' y='54' width='293.6' height='293.6'");
      storeData(3,19,'DOGE',"M273.6,108.1v-0.2c-16.6,2.5-34.1,1.6-50.3,5.7c-26.7,29.6-23.6,3.5-46-10.3c-8.1-7.4-30.1-7.4-38.2,0c-22.4,13.8-19.3,39.9-46,10.3c-16.2-4.1-33.7-3.2-50.3-5.7v0.2C31,105.2,60.3,136,62.7,139.2c16.2,16.8,28,37,43.1,54.7c23.8,19.3,36.2,95,52.4,103.3c16.3-8.5,28.6-83.8,52.4-103.3c15.1-17.7,26.9-37.9,43.1-54.7C256.1,136,285.4,105.2,273.6,108.1z","y1='61' y2='260'","x='4.9' y='31' width='290.2' height='306.4'");
      //EYES
      storeData(4,0,'Duo Round 1',"M125.6,167.5c-11.4-16.8,15.6-31.2,25.5-15S135.3,183.7,125.6,167.5Z","M169.6,167.5c-11.4-16.8,15.6-31.2,25.5-15S179.3,183.7,169.6,167.5Z",'');
      storeData(4,1,'Duo Round 2',"M137.9,169c28.6-.1,28.6-18.2,0-18.2S109.3,168.9,137.9,169Z","M182.1,181.8c11.8.3,11.8-44.1,0-43.8S170.3,182.1,182.1,181.8Z",'');
      storeData(4,2,'Duo Round 3',"M153.8,167.1c0,8.7-7.1,0-15.9,0s-15.9,8.7-15.9,0C122.5,146.7,153.3,146.7,153.8,167.1Z","M197.8,167.4c0,8.8-7.1,0-15.9,0s-15.9,8.8-15.9,0C166.1,146.6,197.7,146.6,197.8,167.4Z",'');
      storeData(4,3,'Duo Round 4',"M145.4,166.3c20.2-20.2,7.3-33-12.9-12.8S125.1,186.6,145.4,166.3Z","M197,175.4c8.6-8.2-22.8-39.5-30.9-31S188.9,184,197,175.4Z",'');
      storeData(4,4,'Duo Round 5',"M154.3,174.8c8.3-7.9-22.2-38.4-30.1-30.1S146.4,183.1,154.3,174.8Z","M186.9,166c19.6-19.7,7.2-32.1-12.5-12.5S167.2,185.6,186.9,166Z",'');
      storeData(4,5,'Duo Star 1',"M154,160c0-3.1,0-4-5.7-4.2,3.9-4.3,3.2-4.9,1-7.1s-2.8-2.8-7,1.1c-.3-5.8-1.2-5.8-4.3-5.8s-4,0-4.2,5.8c-4.3-3.9-4.9-3.3-7.1-1.1s-2.8,2.8,1.1,7.1c-5.8.2-5.8,1.1-5.8,4.2s0,4,5.8,4.3c-3.9,4.2-3.3,4.9-1.1,7s2.8,2.9,7.1-1c.2,5.7,1.1,5.7,4.2,5.7s4,0,4.3-5.7c4.2,3.9,4.9,3.2,7,1s2.9-2.8-1-7C154,164,154,163.1,154,160Z","M198,160c0-3.1,0-4-5.7-4.2,3.9-4.3,3.2-4.9,1-7.1s-2.8-2.8-7,1.1c-.3-5.8-1.2-5.8-4.3-5.8s-4,0-4.2,5.8c-4.3-3.9-4.9-3.3-7.1-1.1s-2.8,2.8,1.1,7.1c-5.8.2-5.8,1.1-5.8,4.2s0,4,5.8,4.3c-3.9,4.2-3.3,4.9-1.1,7s2.8,2.9,7.1-1c.2,5.7,1.2,5.7,4.2,5.7s4,0,4.3-5.7c4.2,3.9,4.9,3.2,7,1s2.9-2.8-1-7C198,164,198,163.1,198,160Z",'');
      storeData(4,6,'Duo Star 2',"M134.1,149.8a4.4,4.4,0,0,1,8.3,0,4.5,4.5,0,0,0,4.3,3.3,4.4,4.4,0,0,1,2.8,8,4.5,4.5,0,0,0-1.7,5.3,4.4,4.4,0,0,1-6.8,4.9,4.4,4.4,0,0,0-5.5,0,4.4,4.4,0,0,1-6.8-4.9,4.5,4.5,0,0,0-1.5-5.2,4.4,4.4,0,0,1,2.4-8.1A4.6,4.6,0,0,0,134.1,149.8Z","M177.6,149.8a4.4,4.4,0,0,1,8.3,0,4.5,4.5,0,0,0,4.3,3.3,4.4,4.4,0,0,1,2.8,8,4.5,4.5,0,0,0-1.7,5.3,4.4,4.4,0,0,1-6.8,4.9,4.4,4.4,0,0,0-5.5,0,4.4,4.4,0,0,1-6.8-4.9,4.5,4.5,0,0,0-1.5-5.2,4.4,4.4,0,0,1,2.4-8.1A4.6,4.6,0,0,0,177.6,149.8Z",'');
      storeData(4,7,'Duo Triangle 1',"M149,180.2a1,1,0,0,1-1.6.8c.2-.9-31.3-23.4-27.5-24.5.7.5,29.6-16.3,28.9-12.4Z","M170.9,180.2a1,1,0,0,0,1.6.8c-.2-.9,31.3-23.4,27.5-24.5-.7.5-29.6-16.3-28.9-12.4Z",'');
      storeData(4,8,'Duo Triangle 2',"M139.4,145.5c2-.1,4.6,2.4,11.2,9.1,10.7,10.6,11.1,11,6.3,15.1-6.3,6.5-10.2,6.3-17.5-2.3-7.3,8.6-11.1,8.8-17.4,2.3-4.9-4.1-4.5-4.5,6.2-15.1C134.9,147.9,137.4,145.4,139.4,145.5Z","M181,167.4c7.3,8.6,11.2,8.8,17.5,2.3,4.8-4.1,4.4-4.5-6.3-15.1-13.3-12.4-9-12.4-22.4,0-10.6,10.7-11,11-6.2,15.1C169.9,176.2,173.8,176,181,167.4Z",'');
      storeData(4,9,'Duo Cross 1',"M152.1,146.1c-3.9-3.9-4.3-4.3-14,5.2-9.7-9.5-10.1-9.1-14-5.2s-4.3,4.3,5.2,14c-8.9,9-8.4,9.5-4.6,13.3s4.3,4.3,13.4-4.6c9,8.9,9.5,8.5,13.3,4.6s4.3-4.3-4.6-13.3C156.4,150.4,156,150,152.1,146.1Z","M196.1,146.1c-3.9-3.9-4.4-4.3-14,5.2-9.7-9.5-10.1-9.1-14-5.2s-4.3,4.3,5.2,14c-8.9,9-8.4,9.5-4.6,13.3s4.3,4.3,13.4-4.6c9.1,8.9,9.5,8.5,13.3,4.6s4.3-4.3-4.6-13.3C200.4,150.4,200,150,196.1,146.1Z",'');
      storeData(4,10,'Duo Heart',"M146.4,148c-4.6,0-8.3.7-8.3,6,0-5.3-3.9-6-8.5-6s-8.9,8.8-4.3,13.5l8.3,8.4c6.1,6.7,13.3-5,17.3-8.4S152.7,148,146.4,148Z","M190.4,148c-4.6,0-8.3.7-8.3,6,0-5.3-3.9-6-8.5-6-6.2.1-8.9,8.8-4.3,13.5,3.6,2.7,9.5,13,15.2,9.9,1.7-.4,9-8.8,10.4-9.9C199.5,156.8,196.6,148.1,190.4,148Z",'');
      storeData(4,11,'Duo Sus 1',"M157.7,150.1c-.1,25.7-39.1,25.7-39.2,0Z","M201.8,150c-.1,26.1-39.7,26.1-39.8,0Z",'');
      storeData(4,12,'Duo Sus 2',"M156,172.7l-6.5-7.1-20.4-4.9-8.8-13.4c8.9,5.4,19.4,6,28.5,8.6Z","M163.9,172.7l6.5-7.1,20.4-4.9,8.8-13.4c-8.9,5.4-19.4,6-28.4,8.6Z",'');
      storeData(4,13,'Duo Sus 3',"M155.5,163.8c4.1,9.6,2.3,18.7.2,19s-3.8-10.1-17.1-12.9-9.8-18.9-1-18.9C150.2,151,154.3,160.9,155.5,163.8Z","M164.2,163.8c-4.1,9.6-2.3,18.7-.2,19s3.8-10.1,17.1-12.9,9.8-18.9,1-18.9C169.5,151,165.4,160.9,164.2,163.8Z",'');
      storeData(4,14,'Duo Sus 4',"M158,179.3,125.4,165c-7-3.3,14.6-28.4,22.4-10.8C153,165.9,153.5,177.4,158,179.3Z","M162.1,179.3,194.7,165c7-3.3-14.6-28.4-22.4-10.8C167.1,165.9,166.6,177.4,162.1,179.3Z",'');
      //PUPILS
      storeData(5,0,'Round',"M138.5,168c-7.8,0.6-7.7-17.6,0-17C146.3,150.4,146.2,168.6,138.5,168z","M182.5,168c-7.8,0.6-7.7-17.6,0-17C190.3,150.4,190.2,168.6,182.5,168z",'');
      storeData(5,1,'Triangle',"M138,154.2l6.1,11.6h-12.1L138,154.2z","M182,154.2l6.1,11.6h-12.1L182,154.2z",'');
      storeData(5,2,'Square',"M132,154h12v12h-12V154z","M176,154h12v12h-12V154z",'');
      storeData(5,3,'Star',"M138,154.3l1,3.9l3.7-1.7l-2.5,3.2l3.6,1.8l-4.1,0.1l0.8,4l-2.6-3.1l-2.6,3.1l0.8-4l-4.1-0.1l3.6-1.8l-2.5-3.2 l3.7,1.7L138,154.3z","M182,154.3l1,3.9l3.7-1.7l-2.5,3.2l3.6,1.8l-4.1,0.1l0.8,4l-2.6-3.1l-2.6,3.1l0.8-4l-4.1-0.1l3.6-1.8l-2.5-3.2 l3.7,1.7L182,154.3z",'');
      storeData(5,4,'Dollar',"M137.8,157.1c0.8,0,1.1,0.4,1.2,1.2l1.6-0.2c-0.1-1.5-1-2.2-2.1-2.3v-1.1H137v1.1c-1.2,0.3-2.1,1.1-2.1,2.4 c-0.2,3,3.7,1.8,4.1,3.8c-0.1,1.6-2.9,1.2-2.8-0.4l-1.6,0.3c0.2,1.7,1.2,2.3,2.2,2.4v1h1.6v-1c3.3-0.4,3-4.9-0.1-5.1 C136.7,159.1,136,157.2,137.8,157.1z","M182.3,157.1c0.8,0,1.1,0.4,1.2,1.2l1.6-0.2c-0.1-1.5-1-2.2-2.1-2.3v-1.1h-1.5v1.1c-1.2,0.3-2.1,1.1-2.1,2.4 c-0.2,3,3.7,1.8,4.1,3.8c-0.1,1.6-2.9,1.2-2.8-0.4l-1.6,0.3c0.2,1.7,1.2,2.3,2.2,2.4v1h1.6v-1c3.3-0.4,3-4.9-0.1-5.1 C181.2,159.1,180.5,157.2,182.3,157.1z",'');
      storeData(5,5,'Diamond',"M138,152.2l7,7.8l-7,7.8l-7-7.8L138,152.2z","M182,152.2l7,7.8l-7,7.8l-7-7.8L182,152.2z",'');
      storeData(5,6,'Line',"M133.7,161c-4-2.4,5.5-4.5,9-2.2S137.1,163.4,133.7,161z","M177.7,161c-4-2.4,5.5-4.5,9-2.2S181.1,163.4,177.7,161z",'');
      storeData(5,7,'Line 2',"M143.8,162.5H131.5c-3.2,0-3.2-5,0-5h12.3C147,157.5,147,162.5,143.8,162.5Z","M188.5,162.5H176.2c-3.2,0-3.2-5,0-5h12.3C191.7,157.5,191.7,162.5,188.5,162.5Z",'');
      storeData(5,8,'Plus',"M142.9,158H140c0-1.5,0.5-4.5-1.9-4.5c-2.3,0-1.8,3-1.9,4.5c-1.5,0-4.5-0.5-4.5,1.9c0,2.3,3,1.8,4.5,1.9 c0.1,1.5-0.5,4.8,1.9,4.7c2.4,0,1.8-3.2,1.9-4.7h2.8C145.3,161.8,145.3,158,142.9,158z","M186.4,158h-2.6c0-1.5,0.5-4.5-1.9-4.5c-2.3,0-1.8,3-1.9,4.5c-1.5,0.1-4.8-0.5-4.7,1.9c0,2.4,3.2,1.8,4.7,1.9 c0.1,1.5-0.5,4.8,1.9,4.7c2.4,0,1.8-3.2,1.9-4.7h2.6C188.8,161.8,188.8,158,186.4,158z",'');
      storeData(5,9,'Heart',"M138.2,159.6c1-2.1,4.8-3.8,5.2,0.5c0,2.9-5.2,3.1-5.2,5.2c0-2.1-5.2-2.3-5.2-5.2 C133.5,155.9,137.2,157.5,138.2,159.6z","M181.8,159.6c1-2.1,4.8-3.8,5.2,0.5c0,2.9-5.2,3.1-5.2,5.2c0-2.1-5.2-2.3-5.2-5.2 C177,155.9,180.8,157.5,181.8,159.6z",'');
      storeData(5,10,'Cross',"M140.4,160c1-1,3.5-2.8,1.9-4.3c-1.6-1.6-3.3,0.9-4.3,1.9c-1-1-2.7-3.3-4.2-1.7c-1.6,1.5,0.8,3.2,1.7,4.2c-1,1-3.3,2.7-1.7,4.2c1.5,1.6,3.2-0.8,4.2-1.7c1,1,2.8,3.5,4.3,1.9C143.9,162.8,141.4,161,140.4,160z","M185.1,164.8c1.5-0.2,2.4-1.9,1.2-3l-1.9-1.9c1-1,3.3-2.7,1.7-4.2c-1.5-1.6-3.2,0.8-4.2,1.7c-1-1-2.7-3.3-4.2-1.7c-1.6,1.5,0.8,3.2,1.7,4.2c-1,1-3.5,2.8-1.9,4.3c1.6,1.6,3.3-0.9,4.3-1.9C182.7,163,184.1,164.9,185.1,164.8z",'');
      //MONO EYE
      storeData(6,0,'Mask 1',"M124.5,157.5a11.4,11.4,0,0,1,11.4-11.4h48.7c19.3,1.6,11.4,28.7-6.1,22.8-12.5-4.9-24-4.9-36.5,0C133.9,171.8,124.5,166.1,124.5,157.5Z",'','');
      storeData(6,1,'Mask 2',"M130.5,147h59a13,13,0,0,1,13,13h0a13,13,0,0,1-13,13h-59a13,13,0,0,1-13-13h0A13,13,0,0,1,130.5,147Z",'','');
      storeData(6,2,'Mask 3',"M131.3,159.4c-6-5.7-1.7-15,6.7-15h44c27.4,6.3-11.9,32.6-22,31.2S139.8,167.4,131.3,159.4Z",'','');
      storeData(6,3,'Mask 4',"M202,155c0-9.3-18.8-6.3-42-6.3s-42-3-42,6.3,18.8,16.8,42,16.8S202,164.2,202,155Z",'','');
      storeData(6,4,'Cross 1',"M187.9,163.1l-5.2-3.1c18.7-7,10.8-29.8-6.1-22.8L160,146.8l-16.6-9.6c-16.5-7.1-25.2,15.7-6.1,22.8-18.7,7-10.8,29.8,6.1,22.8l16.6-9.6,16.6,9.6C189.2,190.4,200.9,170.2,187.9,163.1Z",'','');
      storeData(6,5,'Round 1',"M187.7,160A27.7,27.7,0,1,1,160,132.3,27.7,27.7,0,0,1,187.7,160Z",'','');

      //MONO PUPIL
      storeData(7,0,'Square',"M173.9,161.6l-2.6-1.6c8.9-2.9,5.9-15.2-3-11.5l-8.3,4.9-8.3-4.9c-8.9-3.7-11.9,8.6-3,11.5-8.9,2.9-5.9,15.2,3,11.5l8.3-4.9,8.3,4.9C174.6,175.3,180.3,165.1,173.9,161.6Z",'','');
      storeData(7,1,'Line',"M173.2,165.2H146.8a5.2,5.2,0,1,1,0-10.4h26.4C180.1,154.6,180.1,165.4,173.2,165.2Z",'','');
      storeData(7,2,'Circle',"M160,178c23.7-.4,23.7-35.6,0-36S136.3,177.6,160,178Z",'','');
      storeData(7,3,'Square',"M169,151H151v18h18Z",'','');
      storeData(7,4,'Plus',"M169.5,155.8h-5.3c.1-3.4.8-9.6-4.2-9.5s-4.3,6.1-4.2,9.5c-3.4-.1-9.6-.8-9.5,4.2s6.1,4.3,9.5,4.2c-.1,3.4-.8,9.6,4.2,9.5s4.3-6.1,4.2-9.5h5.3C175,164.3,175,155.7,169.5,155.8Z",'','');
      storeData(7,5,'Heart',"M169.3,146.7c-5.1,0-9.3.8-9.3,6.7,0-6-4.3-6.8-9.5-6.7-6.8.1-9.9,9.8-4.8,15s12.5,16.9,19.3,9.4l9.3-9.4C179.4,156.4,176.2,146.7,169.3,146.7Z",'','');
      storeData(7,6,'Dollar',"M171.5,158.7c-6.2-1.1.1-6.8,1.2-1.7l2.8-.4a3.7,3.7,0,0,0-3.6-3.9v-1.9h-2.7v1.9c-5.3,1-4.3,8.3.7,8.6,1.5.4,2.9.8,2.9,2.2s-5.1,2-4.8-.7l-2.7.5c.8-5.2-6.4-3.4-7-6.8s4.1-2,3.9.5l2.8-.4a3.8,3.8,0,0,0-3.6-3.9v-1.9h-2.7v1.9c-5.3,1-4.3,8.3.6,8.6,1.6.4,2.9.8,2.9,2.2s-5,2-4.8-.7l-2.5.4c.7-5.1-6.4-3.3-7-6.7s4.1-2,3.9.5l2.8-.4a3.7,3.7,0,0,0-3.6-3.9v-1.9h-2.7v1.9c-5.3,1-4.3,8.3.7,8.6,1.5.4,2.8.8,2.8,2.2s-5,2-4.7-.7l-2.8.5c.3,3,2,3.9,3.9,4.2v1.7h2.7v-1.7a4.4,4.4,0,0,0,3.9-3.4,4,4,0,0,0,3.7,3.4v1.7h2.7v-1.7a4.5,4.5,0,0,0,4.1-3.8,4,4,0,0,0,3.8,3.8v1.7h2.7v-1.7C177.4,166.8,176.9,159.1,171.5,158.7Z",'','');
      storeData(7,7,'Diamond',"M141.6,160,160,141.6,178.4,160,160,178.4Z",'','');
      //ACCESS
      storeData(8,3,'Hat',"M178.4,43.2c5.8-31.6-42.1-31.6-36.3,0-20.7,5.5-.7,11.6,18.1,11.4S199.1,48.6,178.4,43.2Z",'','');
      storeData(8,4,'Halo',"M160,43.4c-9.2,0-18.5-1.2-22.1-3.4-1.8-1.2-2.2-2.5-2.1-3.5s.3-2.3,2.1-3.5c7.2-4.6,37-4.6,44.2,0,1.8,1.2,2.2,2.5,2.1,3.5s-.3,2.3-2.1,3.5C178.5,42.2,169.2,43.4,160,43.4Zm0-10.6c-13.9,0-20.6,2.3-21,3.5v.4c.4,1.1,7.1,3.5,21,3.5h0c13.9,0,20.6-2.4,21-3.6h0v-.2c-.4-1.2-7.2-3.5-21-3.5Z",'','');
      storeData(8,5,'Star',"M169,61.8c-9.6-13.3-8.4-13.1-18,0,1.2-16.3,2-15.4-13.7-11.6,11.3-11.7,11.4-10.5-3.2-17.6,16.3-1.7,15.6-.8,9-15.6l12.4,7.8L160,10.9c4.5,15.7,3.4,15.1,16.9,6.1-6.7,14.9-7.1,13.8,9,15.6-14.8,7.1-14.4,6-3.2,17.6C166.9,46.3,167.9,45.6,169,61.8ZM154.7,43.4l-.3,9.2c5.2-7.9,6-7.8,11.2,0-1-9.4-.3-9.9,8.7-7.2-6.9-6.6-6.7-7.4,1.9-11.1-9.4-.6-9.8-1.4-5.6-9.8-7.6,5.6-8.4,5.3-10.6-3.9-2.2,9.3-3,9.5-10.6,3.9,4.2,8.5,3.7,9.2-5.6,9.8,8.7,3.7,8.7,4.6,1.9,11.1Z",'','');
      storeData(8,6,'Crown',"M181.2,55.3H138.8l5.7-20.6,7,9.8L160,17.6l8.5,26.9,7-9.8Z",'','');
      storeData(8,7,'Locket',"M169.2,34.4l-4.5,4.4,1.1,6.2-5.6-2.9L154.7,45l1.1-6.2-4.5-4.4,6.2-.9,2.7-5.6,2.8,5.6Zm-8.9,21.4c-25.5-.4-25.5-38.2-.1-38.7S185.7,55.4,160.3,55.8Zm0-35.7c-21.4.2-21.4,32.6-.1,32.7S181.6,20.3,160.3,20.1Z",'','');
      //
      storeData(9,0,'shape',"dy='-10'",'17','0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0' );
      storeData(9,1,'effect2_innerShadow','','25','0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0');
      storeData(9,2,'effect3_innerShadow',"dy='-16'",'9','0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0');
      storeData(9,3,'effect4_innerShadow',"dy='4'",'5.5','0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0');
    }

    struct Data {
      string name;
      string data1;
      string data2;
      string data3;
    }

    struct Art {
      string[] _colors;
      string[] _colors2;
      mapping(uint256 => Data) _bgs;
      mapping(uint256 => Data) _bodys;
      mapping(uint256 => Data) _faces;
      mapping(uint256 => Data) _eyes;
      mapping(uint256 => Data) _pupils;
      mapping(uint256 => Data) _monoE;
      mapping(uint256 => Data) _monoP;
      mapping(uint256 => Data) _access;
      mapping(uint256 => Data) _filters;
    }
    Art art;

    function storeData(uint8 layer, uint8 index,  string memory _name, string memory _data1, string memory _data2, string memory _data3 ) public  {

      Data storage data = art._bgs[index];

      if(layer == 1){ data = art._bgs[index]; }
      if(layer == 2){ data = art._bodys[index]; }
      if(layer == 3){ data = art._faces[index]; }
      if(layer == 4){ data = art._eyes[index]; }
      if(layer == 5){ data = art._pupils[index]; }
      if(layer == 6){ data = art._monoE[index]; }
      if(layer == 7){ data = art._monoP[index]; }
      if(layer == 8){ data = art._access[index]; }
      if(layer == 9){ data = art._filters[index]; }

      data.name = _name;
      data.data1 = _data1;
      data.data2 = _data2;
      data.data3 = _data3;
    }
    //
    function eyes(ITheCreepz.Creepz memory _dna) internal view returns (string memory) {

        string memory eye;

        if( _dna.typeEye == 0){
          eye = string(abi.encodePacked(
            "<g class='group blink'>",
              "<clipPath id='eyeLClip'><path class='eye faceAnim delay2' d='",art._pupils[_dna.pupils].data1,"'/></clipPath>",
              "<path class='eye faceAnim' id='eyeL' d='",art._eyes[_dna.eyes].data1,"' shape-rendering='geometricPrecision'/>",
              "<use  xlink:href='#eyeL' fill='black'/>",
              "<use clip-path='url(#eyeLClip)' xlink:href='#eyeL' fill='white'/></g>",
            "<g class='group blink'>",
              "<clipPath id='eyeRClip'><path class='eye faceAnim delay2' d='",art._pupils[_dna.pupils].data2,"'/></clipPath>",
              "<path class='eye faceAnim' id='eyeR' d='",art._eyes[_dna.eyes].data2,"' shape-rendering='geometricPrecision'/>",
              "<use  xlink:href='#eyeR' fill='black'/>",
              "<use clip-path='url(#eyeRClip)' xlink:href='#eyeR' fill='white'/></g>"
          ));
        } else {
          eye = string(abi.encodePacked(
            "<g class='group blink'>",
              "<clipPath id='eyeLClip'><path class='eye faceAnim delay2' d='",art._monoP[_dna.pupils].data1,"'/></clipPath>",
              "<path class='eye faceAnim' id='eyeL' d='",art._monoE[_dna.eyes].data1,"' shape-rendering='geometricPrecision'/>",
              "<use  xlink:href='#eyeL' fill='black'/>",
              "<use clip-path='url(#eyeLClip)' xlink:href='#eyeL' fill='white'/></g>"
          ));
        }

        return eye;
    }
    function background(ITheCreepz.Creepz memory _dna) internal view returns (string memory) {

      if(_dna.bgLen > 0){
        if(_dna.bg < 6){
          return string(abi.encodePacked(
            "<path id='bgAnim' d='",art._bgs[_dna.bg].data1,"' />"
          ));
        }
      }
      return "";
    }
    function gradients(ITheCreepz.Creepz memory _dna) internal view returns (string memory) {

      string memory bodyColor2 = _dna.bodyColor1 == _dna.bodyColor2 ? art._colors2[_dna.bodyColor1] : art._colors2[_dna.bodyColor2];
      string memory faceColor2 = _dna.faceColor1 == _dna.faceColor2 ? art._colors2[_dna.faceColor1] : art._colors2[_dna.faceColor2];

      return string(abi.encodePacked(
        "<linearGradient id='gradBg' x1='160' y1='0' x2='160' y2='320' gradientUnits='userSpaceOnUse'>",
          "<stop stop-color='", art._colors[_dna.bgColor1],"'/>",
          "<stop offset='1' stop-color='", art._colors[_dna.bgColor2],"'/>",
        "</linearGradient>",
        "<linearGradient id='gradBody' x1='160' x2='160' ",art._bodys[_dna.body].data2," y2='320' gradientUnits='userSpaceOnUse'>",
          "<stop stop-color='",art._colors[_dna.bodyColor1],"'/>",
          "<stop offset='1' stop-color='",bodyColor2,"'/>",
        "</linearGradient>",
        "<linearGradient id='gradFace' x1='160' x2='160' ",art._faces[_dna.face].data2," gradientUnits='userSpaceOnUse'>",
          "<stop stop-color='",art._colors[_dna.faceColor1],"'/>",
          "<stop offset='1' stop-color='",faceColor2,"'/>",
        "</linearGradient>"
      ));
    }
    function filters(ITheCreepz.Creepz memory _dna) internal view returns (string memory) {

      string memory filter;
      string memory innerShadow;
      string[2] memory  filts = [art._bodys[_dna.body].data3, art._faces[_dna.face].data3];
      string memory feColorMatrix = "<feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/>";

      for (uint256 i = 0; i < 4; i++) {

        string memory overlay = i > 0 ? 'overlay' : 'normal';
        innerShadow = string(abi.encodePacked(innerShadow,
            feColorMatrix,
            "<feOffset ",art._filters[i].data1,"/>",
            "<feGaussianBlur stdDeviation='",art._filters[i].data2,"'/>",
            "<feComposite in2='hardAlpha' operator='arithmetic' k2='-1' k3='1'/>",
            "<feColorMatrix type='matrix' values='",art._filters[i].data3,"'/>",
            "<feBlend mode='",overlay,"' in2='",art._filters[i].name,"' result='effect",(i+2).toString(),"_innerShadow'/>"
        ));
      }
      for (uint256 i = 0; i < filts.length; i++) {
        filter = string(abi.encodePacked(filter,
          "<filter id='filter",i.toString(),"' ",filts[i]," filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'>",
            "<feFlood flood-opacity='0' result='BackgroundImageFix'/>",
            //
            feColorMatrix,
            "<feOffset dy='24'/>",
            "<feGaussianBlur stdDeviation='28'/>",
            "<feComposite in2='hardAlpha' operator='out'/>",
            "<feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow'/>",
            "<feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.8 0'/>",
            "<feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow' result='shape'/>",
            //
            innerShadow,
          "</filter>"
        ));
      }
      return string(abi.encodePacked(
        filter,
        "<filter id='grain'>",
          "<feTurbulence type='fractalNoise' numOctaves='1' baseFrequency='.9' result='f1'/>",
          "<feComposite in='SourceGraphic' in2='f1' result='f2' operator='in' />",
          "<feBlend in='SourceGraphic' in2='f2' mode='overlay'/>",
        "</filter>"
      ));
    }
    function access(uint8 nb) internal view returns (string memory) {
      if(nb > 2){
        if(nb < 8){
          return string(abi.encodePacked(
            "<path id='access' fill='gold' stroke='none' stroke-width='3px' d='",art._access[nb].data1, "'/>"
          ));
        }
      }
      return "";
    }
    //
    function getCreepz(ITheCreepz.Creepz memory _dna) public view returns (string memory) {

        return string(abi.encodePacked(
            "<path filter='url(#filter0)' class='body-fill bodyAnim' d='",art._bodys[_dna.body].data1, "' shape-rendering='crispEdges'/>",
            "<g class='face faceAnim'>",
              "<path class='face-fill' filter='url(#filter1)' d='",art._faces[_dna.face].data1, "' shape-rendering='crispEdges'/>",
              eyes(_dna),
              access(_dna.access),
            "</g>"
        ));
    }
    function getDefs(ITheCreepz.Creepz memory _dna) public view returns (string memory) {

        return string(abi.encodePacked(
              background(_dna),
              gradients(_dna),
              filters(_dna)
        ));
    }
    function getArtItems(ITheCreepz.Creepz memory _dna) public view returns (string[17] memory) {


        string memory bgFill = _dna.bgFill == 0 ? "Stroke" : "Fill";
        string memory typeEye = _dna.typeEye == 0 ? "Duo" : "Mono";

        string memory eye = _dna.typeEye == 0 ? art._eyes[_dna.eyes].name : art._monoE[_dna.eyes].name;
        string memory pupil = _dna.typeEye == 0 ? art._pupils[_dna.pupils].name : art._monoP[_dna.pupils].name;

        string memory bg;
        if(_dna.bg < 6){
          bg = art._bgs[_dna.bg].name;
        }
        if(_dna.bg == 6){
          bg = 'Mountain';
        }
        if(_dna.bg == 7){
          bg = 'Sea';
        }
        if(_dna.bg == 8){
          bg = 'Spiral';
        }

        return [
          art._colors[_dna.bgColor1],
          art._colors[_dna.bgColor2],
          bg,
          bgFill,
          (uint256(_dna.bgAnim)+1).toString(),
          uint256(_dna.bgLen).toString(),
          art._bodys[_dna.body].name,
          art._colors[_dna.bodyColor1],
          art._colors[_dna.bodyColor2],
          art._faces[_dna.face].name,
          art._colors[_dna.faceColor1],
          art._colors[_dna.faceColor2],
          (uint256(_dna.faceAnim+1)).toString(),
          typeEye,
          eye,
          pupil,
          art._access[_dna.access].name
        ];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

/// @title OniiChain NFTs Interface
interface ITheCreepz {
    /// @notice Details about the Onii
    struct Creepz {
        uint8 bgColor1;
        uint8 bgColor2;
        uint8 bg;
        uint8 bgFill;
        uint8 bgAnim;
        uint8 bgLen;
        //
        uint8 body;
        uint8 bodyColor1;
        uint8 bodyColor2;
        //
        uint8 face;
        uint8 faceColor1;
        uint8 faceColor2;
        uint8 faceAnim;
        //
        uint8 typeEye;
        uint8 eyes;
        uint8 pupils;
        //
        uint8 access;
        //
        bool original;
        uint256 timestamp;
        address creator;
    }

    /// @notice Returns the details associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Onii
    /// @return detail memory
    function details(uint256 tokenId) external view returns (Creepz memory detail);
}