// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "Ownable.sol";
// import "MerkleProof.sol";
// import "Pausable.sol";
import "ERC721Enumerable.sol";
// import "MerkleProof.sol";

// @author: Voxel City
/*
iiiilsisltV$$$PyyyVeyye$%%PPyliiii.ilyytiiePi.l$&###########%########@#@##@@##@@@@##@@@##&&&&##%$$PP$$oo%$PPP$#&oxCtse&#&$#$$oxyPytylltPPP$$siiiP##&Viiiiisslisee%$eVo$##&yiiiyo$%$e$&&&##########&&##&%$%########PCiiiiiiiiiiiiiiix##@#######&########@#@##@@##@@@####@@#%######y%##%e##&y%#$ssssxssiiisePPPyo$$P%%$&#@@@@
iiiiiiiiiCyyy$PPPoeVV$%$PPVyCllyCoiiiio$$Pssiis$&#####%#######@%&####@@####@@@@@####@@######%%$PP$%%&%yyPP$$PeoiiixtiiitP%###@%$eCCPesyP%&%PoCliilo%&PCiCP%$ytsPeePP$%#%ollye%%e$%%%&########&%&#####%%%&############$oliiiiiiiiiiiy##@#%########%%####@###&#@@@@######@@#&######o###$o###o&#$ssslsssl...iisyeP$PyP%P$&%&##
iiiiiiltytiilyP$$$$&%%$eoeeCxsl$%&$e$$$PCtCoeye%##################&##@####@@@#@@#@#@@@########&%&&$$P$yo%Pyliilye$%$yiiiyPoP%###@#$Vyxy$$$yiiCyVyxiiiy$&%PtiiV$$P$&&$yllo$%&%$PeePytyP%#####&####&%%&&######%%##@@%&####&PCiiiiiiiisP#@#####@#######&&######@@##@#####@@@##@@@@##V%##$e#@#V%&$Cssssslssyi....iiCVPP$yV$$%##
iiilsllCeeytliiisoPPeoV$%$%$PytCoP$PyCtyooyxile$&###@%######&#@#####@@@@##@@##@@@@##@@@####&&%&$$$$$%$CVoiiilP%$PylisV%###$PeyP%###&#%$&##PV$yiisyoytliitP%%PoP&%VsixV$&&%$$$$PCyVPPoyCyo$####&%%&############&####&%$&#####$osiiiiii&#&####@####&#####@@@###@##@@@##&#@@#%#####&y#@@%V#&%y&@##%Pysllly#$.iii...iisyeee%$Py
lllsCyo$$eoCsiiiiiiilVP$%$$$$$$$PyCCyoVyCCxliit%&&$%&%%#######@#&###@@####@@@@@@######%%#####&%$$$PoCsiV$%etiiliiy$###@@####&$&&$o$#@##@@@&PxstPelisyooCsiiiyPyilyP%&%$$$$$eyyeeeoCsyoyePyCVP%&#################@#&%&##%#######&PylsC$%%%#&#@#####%&###@####@@@@@######&%%#@@#@#@P&##Pe###e&#######$otC$$.P#%i.i....iislyeP
lxyyV%%$%$PCliiiiiiiiP$$P$$$$oyCyVVyCty%$Cxi.is$%$PeeP$%%%@#&#@#####@@#@#@@@@#@####&%%%#######&eyyCy%$e%##&#&$e%#####@#########&[email protected]@@@@@@##$xxssVPsiiCyeyxlso$%%%$$$$$VCoPPVCyyCCsVoooPPeeVCV$%###############@@#$oe$%#@@#&&#####&$$PP$%%&###########@#@##@@#####&%%$%%&&#@@###o%##$P###V%#@########$&e.V&&si#$x...ixieP$
ilistoPeysiiiiiiiilVee$$PPoyyooVyCo$VCy$VCxiiil$%$P&%PPPP$%&%#@&##@@@@@#&##@####&%%&##&&####&%lii$$VoPe$%$%&&&####@#&$eVe%###%[email protected]@@@@@@@##$P$ytssV$CiisCo$%$PP$PeyyVeeCllxCoCCyxyy$%%%ysslyCsCe$&###&#########&$Vyyy#@#&##&%&##%P%&$$Pe$$%%##%&####@@@#&####&%%$%%&#%$%#@####V#@#%e###V##%yP########%.y$$ii&#%.VPP&$#&$
ilxtsliiiiiiiiissyoP$$PVyePeoCCP$yP$oCCVeCtiiiC%&#%$PP%#$PPPP%&%&###@@#P$###&%%%&##&&#########iiiisyP$eoPe$%P$%#####%P$#&$eyCCCCy$&@@@@@@@@@###$#&&&oCsly$VlisoeeysloPVtilsyotltyyCs$%$%$Pe$eiiiisyyooP%####&%$PPPPPeeoo#@@#&%&##&#@@#%$%&$$PeP$%%%&&###&####&%$$%%##%%&###@@@@##P%&#$P###P&###$yCV%####$.P&&si$$e.$####@#$
CsiiiiiiiiistCVtsPPP$PoeoCyPVCC$PCyoyCo&PyCtliy%##@@@&%$$$&&$$$P$$eCsCPCP%%&&###&&##@@@@######Pti..iiisyPPePVe%$P&###$VCsxtstV$o%@@##@@@@@##@#%$####&##%CCsse%eliiiiCCCCyoe$$$%VyCssyCCCV%PP$PPyy$$PoxtyP$PeVVeeeeeePePP#@@@#%PoP$#@@@@#&%$$%%$%PoP$$%###&%$$&&&&%%%&&#@@#&#@###&o&##%P##&o&#@#####$oy$#$iy$%si##$.y$%###%$
iiiiiiilstsyeyPtsePe$%VoCCP%VCCyVyP%VCyyyyC$$ly#@@@@@####&&%$%%Ciisl$esisC$#&&######@@####@##&%##xiii..iilyPPPP%&%PytstxsCoC%##P%#@@@@@@@@@@@##%#&######%P%yyPei.iiiiilsCyyoee$$PyCssilCCteP$$$PVCtyyoyCyooVVVVeeeeeePPP$&##%$PVoo#@@@@@####&$P$%$%$oVPPP$&&&&%%######@@@##@@@@##P###$e###P&#%&##@@#####%iP&&li%%%.$######$
iiiisxyteysCV$Vts%PPPPooCCyyyCy%$yoVyCo%$yy%#ty#@@@@@@@@@##&yiiV%#$s$&#VyCiiCP#@@@#@@@@##########oi#&eii.iiiitCCCsstssCy&##o&##e$#@@@@@@@@@@@##%####%####P#&##@#e....iiiiltxCyyysC$P%ylsye$$PytCyyoyssCooVVoooVVVeeeeePPPPPPPPPPPe#@@@@@@@@@@&o#%$$$Pe$&%&&%&###@@@@##@@@###@@@@#e%##%[email protected]##e$#%ooP%###@##eie&#Ci&%P.V####@#$
lssCoteoeCsxe#Vtx$$P$&VoCCe%eCyeoye$eyV$eyyeeiy#@@@@@###$ylse%##%Poy$Cxlo&#%eCitP&##@@@@@####&%&&Ci###iP%ti.iiCsxsso$&PV###o$#&V%#@@@@@@@@@@@##%########eP####@@%..ii...iiiiiisyCo$%%$P$$VyxtyoyxteetsCoVVoooVoVVeeeVePeeeePPPPP$$#@@@@####@@&y##%VlilisCP%$#@@@@@@###@@@########e#@@&P###e#@%yyyyoeP%##%ie$$li&#%.e%%#&#&$
yysCVeC%PCsxe&VCt$$$$%eoyCePyyyP$y$%VyyePyyPPiy#@@@#&esiy$&##%$%$CP$PCoP%$P$&##$yiiy&#########&##yi%%&i%##isVy$PP$C%#@%o##%y%##$%#@@@@@@@@@@@@@&########&$&$####$..iCi..i..iiiiillCe$PytxyyyCCoysC$exsCooVVVVVeVVVeeeeeeeeePPP$%&##@@@@@####&yiiiisssyiiiiiiC$##@@###@@@@##@@@@@@$###$$#@#P%$eyyCtsxCye&$i$&%Ci$$Pi$####@#$
VyssV&C#$yxto$oCt$$$$$eVyCyPVyy%$yyooye#$oyP$PP&###xiiio&##$lilCyP%ePPyCsiiiiy&##$iilo###########ol#&&ie%&le######o%#&Po###V%##V%#@#@@@@@@@@@##&########&$####@@&......iVi.i..iiiiiilsyyyCCVCe%ossCCxsyeVoVVeVeeeVooeeeeePP$%###@####@@##$yiiillsC$&%#olii.iiiise%#@##@@@#&#@@###e##@&P#&%VoyCsxyVesssC$PiPo%Cl#&PiV%####%$
PyssV#C$eCxxyPCsssCP$#Peyy$%eyyoVyP%PyVPooyoVP%##$oooyliilo$&$oliiyP%##PliCP%%PCilyP%%$%#@###&%##yl&##s%#&ly######y%##$V###o%##P%#####@@@##@@@#&########%$####@#%..soi..i.iys.....iiyCCCssP%yCyxsC$Pts$#$$eoVeVeeeVeeeeP$%########&&$%Pliiilslllllo##&lii......iiilyP%#####@@####$###$V$$oylsoP%&%yCyoCsssey%Cl&&%i$%&####$
%yssyPt$VCssCsxCyeP$$$PPyyooooo%$oePooe%%Vo$$$#@#$CtlsCeVysiiiy%&$yiiiCP%%PCisyP%%%$eP$%#@@#V####Ps#&&l$##CV######y&##$o###V&##P%###########@@@####@#####$######&..ii..iyi.....loi..iy%PxsxCxo$osCeCxs$#&@##&$eoVVeP$&###########$esiiisyPoye$$$iio%&Psly$Ci.......iiilyo$&#@####PP$$oCtCCP$e#%##&&%$&$%%osxoCy$%$i$##@#@#%
PCssyPtCssssCo$$&#%%%#$PoyP%PooPeoe$PoP#%P$&%$&##CsPPsCsltoootiiiy$&%%$oliCe$%%$PP$$%#$$###&x####VC###s$&%xP##@@##o%##$e###e%##P%@@@##&%$#@@######@@##@#%$####@@&..ii..iliioi...i..istoCsso$yoPCstPeCs$&%##@@@##%PV$&########%$ylii.iiisy$P$$$&$iiiiiC$%P$PP%yii..iiiilyoCCo$%%%$ooytye$$yP%P#$##$$&&###@#&ooiisCos$&####&%
VCsstssstCe$&#####%%$&$PoyP$eoo$$e$&$P$%&%$Pe$##@#&eCso$yxClsyVotliilisyP%%%$PP$$&#$$%#####%x&###ex&&#x%##Cy&####%y%##%e##&o&#@$&@@#####$#&%&######@##@##%#&#@##%..loi.ii..ii..ii..ilxeessoeCCoysy%PCx$#&$P%@@@@@##PoV$%&#&##iiiili....iiilCP$Ps%&$siiiyoe%PoCliiiiiiiiCyyCxC%%eClyP%&###PPyo$e######@###@#e&#$ylsxxyVe$##P
CslssCy$%&###@####%%%%$PooVPPoe&&P%&&&%$$PeePP&######$yCsC$esCssCooCy$%%%$P$$%#&$%%%#@####@&C$%&#Py##&CP##y$######e&##Pe###P###$&@@@@#&$%@###%%%&#####@##%###@@@&..ii..iPiii...iCi.isC$VssCoCP%ostCyCt%@@####@@##%eVVVoVP$%&&i....i.......iiilsiCCVestsiiilliiiiiiiiilsCCsllt$yiilsy$##@@#&$%oV$$oo$Pe&#@@$y$##&PsxCe#&yCCy
sxCV$#############&%%#$PVo$#$eP&#%%%$PP%%eyCCoePPP%###$&%Petso$sCsisePeP%%%#%$%&####@#%$eoPPy$%##ey###y%#&yP######o%##%[email protected]##P&##&#@##%$$$$$$%####&$$%&###&%###@@@%.iCei.iiiios..i...issCCsse$yyyCsy%$CC%@@@@@#&$eeVVoeVePeePP$l..iiiii.........iiilV%$ytiiiiiiiiiillsxyyyyCsxe$oiiiiiilCP%$P%%oliiiiiii$####%$eCCyyCllVPyCsy
P$&###################$PeV$#&%%%$P$%$eeeoyooeVVVee$#########Peyso$CCsP$&&$%&##@@@@#&$oClliiiCoe&#$y#&&y%##VP######V&##%P###$#@#&%$$$$&#&$%$$$$$&###&$$$%&%&&#@@#%iiisi.ixi.ii..soi.isC$PtsCyty$oty$oCC%@##%PeeeVoV%%##&%PPPeeiiiiiisVel..........iiisiiiiiiiiilstyVye$oCsssstPylysiiiiiiiiiiiiiiiiiiiiiiCoClxyytP&elilsP$xo
#############@####&####%$%%%%$P$%PPPVyoVeP$eeeeeeP$##%$########PCiiiiils$##@@@##&$$Piiio$$VtiiiloPP###o$##o%##@@#@P&##[email protected]@@%&%PP$$&##@#%$&#&%$PPPP$#&&&$PP$%&###%iilii.iyiiCi..iii.isCPyssyPyV$ytCoeCCP$PeeVoe$$%##%#@@@#&%$P....iiio$&oi...........iiiiiiilssCo###%PysssliisPysoeeysiiiiiiiiiiiiiiiiilsyCiiiiil$#%yClsP$Ve
##################&&&&%%$$$%$PePeooePPPPeoe%%$PPPP$######&##&%ello$##&oiiiy$$$$$$$###$osisye$PoliisyP$yC&#ee#####&e#@@#$&$PP$$$%#@@@@@@#%###@##%$eVoVP$%&#%eoP%%elioPiiiiiili..ili.isCeeCxVPCCoyCy&$oe$%PVP%###$$%#%####@@@@#oi......iiseiiVyyCi.....iiisxtCoPPoyCsslliiilCyP%Pssiiiiiissi..iiiiiiilsllCeeoCliiiiiisy##%%Vo
#################&%%%&$$PP$$eyooePPPPPPP$%$#@@##%$%##&####$yisV&##%$P%Ps&Cysiiy$$%######%PylixllC$&####yP%e%######$##$eVPPPP$&#&#####&%#$%P%#####%$PyyyyoP$$&#%CsCV$Plii$liii..loi.isy$eCxCVyP%eCe%%%%$V$&%%###%%%#&####@@@@@@@#ei......iiiyyCoyiiiiiilsP##Psslllliiiiit%#####PiiiilxCsiii.....illlsCyo$%PVCsliiiiiiisyxy%&
#############@####&%$PPPVyyoeP$PPeVeP$####P#@@@@@#####eysiC$&##$ey$$$%ylos$#&Pyiiy$#&#######$P%########eP$Vy$##@@#%PeVoV$&&&##&%&&#$&&%#$#@#%&&%&&#@#PCCyyo&&%&#$iilsyeePsiPyi.iii.istCyCtP%V$&%$$$PVy$##%$%############&%#@@@@@#$..ii......iiiiiiilsiiiistiilliiily$esy###$yiiiltyyyyPP%Piiiii.isCyyP%P$$PCliiiiiiiiisxtCe
#############@###&%&%$$PVVP$PPPPP$&#%%@@@#P%#@@@@@#$yiio%##&PyiC$$%$PPClPP%$$%##%PsiiC$%###@####@@@####%&#PxCP####%PVoeeeVP%##@###@%%$PP$%##&&&###&Pyyyyoyy#@@@&oiiCCiilCeePyiiCei.ixy$$CC$&%%$$eoPPyCy$############@#@###$$$&#@##i.y&$ii.....iliiilxsi...iiiiiiy%###$txesiilssiyCyo$$P%%osliiiiiiiisyeeysiiiiiiiilyoCslsV$
###################&%$$$PPPeeP$%###@#%@###P$$$%#@@#Cliilo$#$yliP%&PClsyy%Pyto$&&$ylso$$%#####@@#$$#####%[email protected]@@@#PeeVeeePeeV$##@#PP%%####%$&&%eyyyoyyyyoy#@@&xiiiiliiisisyVCloPiiito&%P%%%$ePVyyPoCxtCP#@#########@@@##@@@#%$$#&i.y##$P..i...iiy$##%Pl..iiyPCiP###$liiisxCyCslxilsty$%ePyCyCPsllxCsliiiiiiiiilllllxyeesV%
#############@########%$P$$%#&$#%P##%P$###&#%%VoPolCoVysliiCP%%oliiiiiCeP$%&%VsitV$%%$Ve#####%oyP$%%$oCxxsso$#####&$P%%$PeVeePeeoP$%###@@@#$eyyyyyyyyoP$%Po#@@&yCCiiiiiiCiisiisyeCilo$%$$PePoePotxCCyyyy$#####@@@@#@@@@###@@@@@##%..y####i.y&es$########%ye&##ylyPsiiistCCCssiio%yssCyCyyslC$&%yytliiiiiiiiilsyslyeyxllssV%
#############@#####@@@#&$&##@#$#$P##%Vy&$etxsoeCCVyyysCyVoCliile%&PCise%%PCilyP%%%$PP%$e%#####&%%PoCxslsCs$###@@@@#$PeP$$%PPPPeeeeVoe$&#%eyyyyyyyyoyP%$PVVe#@@#PyCsliiiiiiisliiiilyVPPeeyCePytCCCCyyyyyV%@#@##@@#@##@@####$&#@@@##i.C&%$%i.y##$$##@@@@@##&%##PiiiilsCyCyeyiiiiiP$oytsCe$&$esiilliiiiiiiilsltVsosllCoPPeyCe%
#######@############@@@&$#@##&$#$P#&%ylliteeyysiisCtyyoVCtyooysiiiy$&$ositV$%%$PVe$$%$eePPPPPPPoCxlillV%&t$##@@@@@#$$%$VCsllxlllsCoeeVoyyyyCCCCye$$yyyyoePe#@@@@&yxiiiliiiiiiiilyiiilCPetssssxCCCtxsyy%#############@@####PPP$%##%i.y##&$..y####@@########PCiiistyyCye$P$%ePexlCClCP&####&PsiiiiiiiiilCsyylsyPVslsslltoPCP&
#####@#######@#%$eP&###&$%###&%&PVylllxeeyliltyii..iisCtyVeVCCyyVCsiiCe$%%%$Ps...........iPeCytlsi...........$##@#&Ci...............iiCyyCoey............iP#@@C...........iii........................P%@%...........%@@###PPeeeP&#i.C&&##i.y#%$&###@@@@#&li..iiiililstVPe%$P%olCsily$%PCiiiiiiiiilllyCyyoClly#$slCePeoCCCe%
@###########&$PP$&#####%$%##&$esisyePClilsyPP$%PeCilliiisCtyVVeyCyyV$%%$Pe$&&%i...........&#%&$%[email protected]@@#y.....................iy$%[email protected]@%..........ieoyy.......................i&#@%...........&@@##%PPPPPe%&i.y##$$..o#####@@@##@@###y.....iiiiilsxCP$Peo%yiiiiiiiiiiiiistxVsltox$$Clly%essssCye$$yP&
#####@###$Pe$%&&&#######&#&yiisoPeyslisCssyP%$$PoyyoVyoCxxsCCyCoVVyCCye%#%$$$$%[email protected]@@##y..........i#@@&.........................lPeeet............##i.........i#@##$.......................i##@&...........&@@@##&%PeeP#%i.y####i.y&&##############y.......iiiiiiiilo$$CiiiiiiiiillCtCoyolll$y%%CllCPyslCeeCCyyyP%
#####&$PP$%&##&$$PP#@####PiiisCyyCxyP$$%yssCyyCyCeyoyee$%$oyV$%Vsly%&&%$$$%###@$..........i#@@#&i..........&@@$...........iP%%C...........i&&$Vy...........so.........i#@@@#%...........iiiiiiiiiiiit###$...........&@@@#&$Peeee##i.y#%%&i.y##$%##@@@@@##%%##i..........iiiiiiiiiiiiiiilsyslCyCy$ylllPyeVtlsCPCliilo$$PoyP%
#&$eeP$&#&%&#%PP$&##@@@##PiiiiiilyyoP$%exllsoeCxCPyyV$$%$$$$PytCyyo$%$$%&&#@@@@#[email protected]@#[email protected]@#...........i#####y...........o&$ePPi...................x######&...........$##@@######@####$...........%@#&$PPeeeee&%i.y##&$i.o###@@@#########@@i.iiii........iiiiiiiilsxxosVsilPPo#ylllysPosllsssssCCCyVP$e$#
ee$%&###&$PP$$%&#@@######&y...iiiiiiCCooyCye$%$%VyyoP$$$PyCxCyoCsP&#@###&#@@##@#&[email protected]@@i.........i#@@C...........y####%P...........i#&[email protected]@####&$.......................%###$...........$##%$Peeeee$##i.y####i.y#%%#####@@##&&###i..sl...i.......iiilCslyyCy$osil$$y$ysllosCslilsCe$%%$$Poyyy$%
&&&&#&%PP$%&###&&#@@@######i..ii..iiiiilsyxVeeP$PPP$$PytCyoyCCyss#@@@@@#&##@##@@@[email protected]&..........e#@#i...........$###%$$............&#%[email protected]@###&%%$.......................%###$...........$##%$PeP$%####i.y#&$%i.V##&&#@@@@@@@####@i..Po...iii..i..ilyxVsilo$y#eslloyCPClllsllssyP%####$yVP$$Pe$&
#$PPP$%&##&#@##&&#####%Pe$%i.iyoi.ii..iiiiityyy$$VyxCyyoCCCssPPsl&#@@#####@@@#@###[email protected]##@#i...........$#####%............%#&&&[email protected]###&%%%[email protected]##P...........$##%$&##@@@@#%i.o####i.V####@@#########@#i..yx...i$iii...iitoosile&y%oslloyCysiilsy$&####@###%$Poyoeo$&
PP$%#@@@#&&####&&&%$oCyoossi..ii..iei.i..iiiiilssCyoyCyCo%ollCCsl#@@@@#####@##@@@@&..........%i.........&##@#i...........o##&%$P...........i##&%PPi..................e#####&&............iiiiiiiiiii&@#&y...........$####@@@@@@###iiy#&%#i.V##$%##@@@@@##&&#$...ii...i&iii...iil%PsiiyeCPylilsllsssyP%####&######$e$%$$eo$&
e&&#@@@##&&###&$PyCye$P$&VyiiiVCi.iiiioC....iilyyCtss$$CyotllV$sl#@@@@##&##@@@@@###[email protected]##@#V...........i####%s...........y##&%$i....................C#&&&##[email protected]@@###@@@@@###%y...........&@@@@@@@#&Pe%%iio##&$iiP####@@@@##@####C....ii...iyiii...iil$PliiyeCexiiissCe$%##############%oyVe$%P$#
$&&$&####&&%$VCCoP$P%#%$#P$iiisCi.isi.ii..yx..ilC$PslyysCVylsVVss#@@@#####@@##@#####[email protected]@&##&$l...........i$&%C...........i####&i.........iV...........s##&&#i..........illliilliiiiis%$C...........isssllli..ilV#iiV####iie#&%####@@@#####$i........ioiii...iiloyliiCssllssyP%###&&&########@###&%$PeeeV$&
$&&t%#&&%PyCye$%##$%##PeeP%oiiliiiieliti..il..isyPyslyeCV$ylstyss#@@@@@@###@##@@@@##P.................&@#$#@@##[email protected]@@#&i..........&#i...........V####i.......................i$$C.......................l#lie#&$%iiP##&&#@@@@@@@####@$sii........i...iiiVCiiillsteP%&###@#&##############&%%%%%$e$&
#&&t$$eyyoP$&##&%&%$##o$###$iiP$iiiiiiyyi.ii..issyyss$PCxCCssP$ss#@@@@#####@@@@####&#i...............t#@@$#@@@@@#l.....................i%@@@#$...........V#&$............s&&&........................y##$.......................P#Vs$###&iiP###@@@@@######@@@$e%#$ii.........iilxlllsyP%###&&#####&##############%P$$$%&P$#
#&%tyCCCye&##$%&%%&&$%Py#@@$iilsiix$siiii.yei.ily%esstCxo%Vssyyss#@@@#####@@##@##&&%$P..............i&@@@P%#@@@@@@#ei...............iC&##@##[email protected]@&Pt............i%%........................#@@%......................i#@$CP####iiP##%###@@@@@##&###$e$#&P&osi......iiiltoP%###@#&&&################@###%PePP$%e$#
PP$yyCCyCCCCe$%####$siiiiiCxilPPliixliPPiiiii.isxCtss$$CyVCssP$xs#@@@@########&%$$%%&#$$%&######%&#######e#@#$%#@@@@@@@#%$oyCCyeP%######&%%$VyoeP$%&####@@@%VVe$######&&%%%&&PyCyP$$$$%%%%%%%%%%&####@@@@#&$P$%########&%$$$$P$%&%PoP##&%ii$####@@@@@@@@@##@@$e%#&P$eee%#ei..iyP&##&&#####&&&###@#&##############%PPPPPPPP$
iiltyyyyCxsCCCCCyCiiiiiiiiiiiisVsiCVlilsiiVoiiisC$PssoyxCPossPexs&#@@######%$$$%%&#%%##@##@@@@@@#&###$#@#P&#@@#$$$&#@@@@@@@@@#####&&&%%$$PeeePP$&#@@@@@@@@@$yoP%@@@@@@@@@#&$PVCtCyooV$$$%%%%&##@@@@@@@@#%oo$#@@@@@@##%$$PPP$$%%#%PCylCe&#ii$######@@@@@####@#$P$#&yCVee%#&eee%&&##&&&&####&######################%PPPPPPPPP
$yliiilyeoCtiiiiiiiiiiiiiiiiisyliilPVlVCiityiiisy$yssoPyP%ossCotx&##@##&%$$%%%#&$%&&#@@@#&#@####P$###V&##o&#@@@@@#%$P%#@@@@@@@@##%$PPPeeeeeeeP%&#########$oyyoeVV%######&PCyytlxV$etllsxyoP%#########%oliiC$P&###$eoyyCxCoP$$&P%PPeCliixyli$#####@@@@@@@@##@@$P%##yteeP%#%Ve$%&&##&&&###@#&#&################@####%$$PPPPPP
CP$$osiiiliiiili.iiiiiiiillslxeVyCiiiiyPiixiiiisxyyss$$CCCCxx$%CC%&#&%$$&%&&%%&###&#@@@@##@@@@##%%##&y%##P#####@@@@@#&$P$&#@@@@@#%%&%$eeeooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooVooVoVooooooooooooooooeyoe$%#%$yssso$#@@@##%%&##@@@#Ve%##yCePP%#&ee$%&&##&&&###########@############@####@###%$$P$
siisyxiiiilsxssi....iiilllsCyoPeoysiiiiiiie%siiso&PssCCCV%Pxx$%$%%$&#&%&&%%#####$$$$$&#@##@@@@@#$$##&o#@#P%#&PP%&#@@@@@@#ys%###P$$$PP%#&$ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooVVe###@@####&esiiiCoe$&%PyCyyeyCsitP$oCPP$%#&ee$%&&###&####################@##########@@@@##&$
%PiiiiistyyyysyCii.ii.ilCyV$%$%$PysiiiiiiiislilsCoCsx$%yP%$V$%$Po$%&#%%%####&$$%&#@##%$$%%######$%@@#o###P#@&eeeeP$%##$PP%%%%PP$$PP###@@&oooooooooooooooVyxliiiilxyoVoooVoyssssssooCsssssssssssssssssyyssssstoVooVooyssssssyooVe#@@@%$%$%&%ylCxiiilyttxlstCtliiiiiitoP$&##$P$&&###&&&###@####################@#&$oy&@@@@@@#
iiiiiiyyyV$e$##PsliiiilsssxV$$PysiiiiiiiiiPPsilxy$Ptx$$P$%$PeeeyC&@@####&%P$%##@@@@@@@##&$eP$#@@%%##&o#@@$%%$PePeeVeVPP%$e$$PP$&%#@@@@@@&oooooooooooVoCi...........iioooVoi.....iooi.................yC......loVoool......iooooe#@@#%PVP%$$$PyllsttsstCCtCiyPyoCsCoo$PeP&#%$%&&&###&############@###########&%PeP%%$%#@@@@@
sxCsiislsCPP$%ootsiixiiissxCsiiiiiiiiiisCy$%yssxo&$oV$$$PeoCCPPtssy##&$P%&#@@@@@#&%##@@@@@#&$ee$$%###V&#%eePPeeeeeeVVVVeeeVy$##@@@@@@@@@&ooooooooooVyi...............iyooo......iVs.................iVoi.....iVoVVi.....iCoVoooe#@@@###$oosisxttste%oliiCPyyP&#%$ee$eCtxC$#&#&&####&#####################%PVP$%&&&#@###$&#@
CCsily$ClsCyyVeCxy&##CyCsiiiiiiiiiilCliyP$%%PyCyP%$$PVeye$VxssCoeePP%&#@@@@@@@@@#&&$P&@@@@##@##&$oo$$oP%$VePPeeVoVeeeVe$$eeP$##@@@@@@@@@%ooooVooVVVi......iyVoVy......iVVi......yVVVoVVoi.....toVooVoooVi.....loyi.....sVVoVVooe#@@@&PylilCyoCiilso$yliiiVPeeliCPossxCCCC$###&##########@############&$eP$%&##&$Pee%@@@@#%%
iiiit&%VyyslyP$eCiilsliiiiiiiiillsyiylioPePP$%$$$eoyCPPyttxCyePP$%##@@@@@@@@@@@@@@####@####@@@@####$eCo$%eeeeeeeeeeP$%##%CV$Pe$&%%Po$##@%ooooVooVoy......ioVVoVoClllllCooi.....iooooVoVt.....iVoooVoooooy.....it.....iyVooooVooe##&eyyoillstCsiiiillliiii$&&&ylssCyCyoP$y$###&&#########@#######@&$eoP$&#&%%&$PP$$$%#@@@@@@
VVyilxCsCV$#####%xiiiiiiiiiisltxilyoyliCVe%%eoyyy$PCxtttyePPP$&##@@@@@@@@@@@@$#@@@@@##############&$oCyye%PePeeP$%###@@@@$e$%PsiCyCCiisePooooVVooVi......oVVoooVooVVooVVx......CooVoVoVi.....loooVVoooooVl..........sVooVoooVooe&&%$PePiCliilslPoxliiillliiistyCCyeP$Poyy%###&################&$eoP$%###&PPP$%%&&%P$$$%##@@
P%$CsCliy$##&PCiiiiiiiiiilClysCsiiC#VliCeooeVVyCCytxCCe$PeP%#@@@@@@@@@@######$##@@@############%PyyyyyV$&&PP$%%##@@@@@@@#VCsCsCo####eiiixoooooooVoi.....ioVooooVVVooooVoi.....iVooooooy......oVooVVooooVoVi.......iyoVooooooVooe##%$P$%soPeysiillCVeytiilsCCtCeP$$PoCCCVy%###&##########@#%$eoe$%&%%##$PP$%&###&&%$$$PPP$%&
$$PsseliiiiliiiiiiiiilxsilyCseosiiC#Vliy$$PeyCsssCyyVe$PPPPeP%##@@@@@@######&P%###@########&$VCyyyyVP&#@##%##@@@@@@@#&PCilCe#%CslssosiiitoooooVoVV......loVVVooCCCCCCooV......sVoooooVi.....iooooVVooooVoot......ioVoVVoooooVooe&#####&oCssCoeoCsiisCoeoysCV$$$eyyCyP$$Py%#############%$eoP$%###%PeeP%&&&&#@##&&%$$PPPPPPP
Csy%#%CliiiiiiiiiislssCtiil$t%%siixeCliyPPP$PeyCyyyyo$&##&PeVooe$&########Poe$%#@@@#####%PyCyyyyyP%#%##@###@@@@@@#%PsilCysyoeP&PeyxPeyysCoooooVooVi.....iooVoyi......yoC.....iooooVVVo......iooVoooooooooVi......ooVoooooooooooe&##%$%%PPeyllsCyeeoClilxye$PoyCyV$$$Poyyy%###&#####%$PoV$%%%%#&$PeP$&#@@#&&####&&%$PPPPPPPP
iiiiiiiiiiiiiiisiiCCsyysiil&yPesiitPCiiise$PPPoyyyP$$#@@@@##%eoyyyyP%#####&&########&$oCCyyyyP%&$$$#%#@@###@@@@@&yCeiiiiy$%$CsliCeoooCliCoooooooVoC.......iii.......CoVi.....ioVVoVool......yoooooooooooVo......ioooooooooooooVe##&&&#&$eP$$PVCslxyePeyCslxCyP$$$eyCyoePo%#######$Vye$%###$Peee$%%&&#@###&&&##&%%$$PPPPPPPP
iiiiiiiiiilllCiyiiiee$%siiiolVyliisslilsC%###%P$####%#@@@@####&%$Vyyyyye$#####@##%eCCyyyV$$$&##&PP$#%#@######@@@@@#$iiiiiiiiiiiiiiiilsCCyoooooVVooVCi............isoVoy......oooooVooi.....ioooooooooooVVi......yoooooooooooooVe####&%&$eytCye$$$eyssxyePPP$$Vyyyoe$$$PoyP$$$PoyV$%%%##%PeeP$&#@##&&#####&&&%%%$$$$$$PPPPPP
...iiiiliiCCsCoCiii$$ePsiiiesyxiiillCVP%$#@@@&P&@@@#%########%$###&$yCCCCCyP%&$yCyyyyo$&##$PP%#&$%&#%#@####PP$&##@@&iCisliiiiiiiisstCxCCoooooooooVoVoysiiiiiiiisoVooVoyiiiiisVooooVooiiiiiiyoVooooooooooosiiiiisoVVooooooooooooe###%%&#$$%$VyCCCyP$$PoCtCCoyyyVP$$PeoyoeV&#&$e$%##$PeeeP$%%&#@@##&&&#&&&%%%$$$$$$$$$PPP$$%#
...ilCiyiiiyeC#yiiioyyysiissilllsCP&#&&&%%###%P&@##&%########&&###&%%#%PCtCCCyyyyye%%$$%##$$$##&eP$&%#@###&PPeeP$%#&iiiiltCliiiiCxsCyooyooooooooooooooVVoVoooVVVVooVooooVVooVVoooooVVooVVooVVoooooooooooVVoVVVooVoooooooooooooVe#######$eyoeP$PVyCCye$%$eyoe$$$PeoyeP%%%P%##&%$$&PVeP$&#@#&%&####&&&%%%$$$$$$$$eytxyV$%##@@
...ilCCCiiie&C&yiiioyyyliiillte$%&###&&##&###%$&##################%$$####$eVtCVP$&##%PP$##%$$&#&P$%#%&####PPPPeVyyVoiyiiiiiisyiixyooVoyyoVePPPPPPP$$$PPP$$P$$P$P$$$$$$$$$PP$$P$$$PP$$%$%%%$$$$$$%$$$%$$$$%%$$$%%%%%%%$$$%%%$P$$$####%&#$$$oCCyoe$$PoyyyoP$$$Voooe$%%$PVoe$%$$eVoe$$%&#@@##&%&###&%%$$$$$$$$PoCsyP&%etsV%#@@
...iis%oiiiyPsetiiiCssiillyP$###&&&##&&######%$&#########@@#########&###$P$&$$&%PP%#%$%###$PP&#&$$$&%$P&@#%$eyCsCxsssClVPyliiiiisyyyooVoyyoP$$%%###&%%%&&#&&&%&#####&%$$%&%&&$###$%#@@@@@@@@@@@@@#@@@@@@#@@@@@@@@@@@@@@@@@@#&&&&##&&###$P$%%$eyyyoP$$$eoyCyyV$%%%$PoVeP$P&#&$P$%##&%%#####&%&%%%$$$$$$$$eyxtV%#######&PysyP
...iis#eiiiCytPxiiilllxoP%&####&&&&##&&##############@#@@@@#############%P$#$$&$P$&#%PP%##%$&##&eP$$$%%##%PCtyoo$PysyssssCyVyxiiiiilsCCxliilCV%%eooeP%$eoePPVo&&&&%$$#%osile$$$P$Co&&####@#&########&####@@@@###@@@@@@@##@@#&&%P%&#####$PoyoP$%$$eVVoe$$$PP%%$PoyoP$%%$$e#@##%%#@#&%%##&&&%%$$$$$$$$PVCsyP&##############$V
...iileCiiiyyslliiitV%##%&&#&###&&###&&###########@@@####@@@#@#@@#######&%%#$$&%$%&#%P$%##%Pe$%$$%&&%$eyCCyeP%#P%$P$yCsxCxssCoPosiiiiiissiiiisytyyyVP$$$%oyCllyCCyP%PP$PPye%$PyxCC$##@#@####&%&######%&&&######@@@#@#####@@%CoVyP%%$%&#$%%$eoyyV$%%%PeVoeePeeeeP$%$$PeePP&#Poe$&##&$y$%%$$$$$$$$$eyCxy$#########yCye$######
...iilPCiiililltoP%#####%&%#&###&&###&&###&##########@@#@@@##@@@@#######%%%#$$&$PP&#&$$%&%$$$%$$#&$ytCyV$#%$%##ePooP$&##%$ysllssCyeiiiiCl..iiiiiiisyyyeePPVCslxilCsCPP$$PeyxCyyyCiC&######&&#####%########@@@###@##@@@@###@&PVyyP$%###@%PePP$$PPVVVP$%%%$eVP$%$$eeeP$%$essyPeCCCV$%PlP$$$$$$PeyCto$&##############$P%######
...iissliiilyP&#&&%#####%&&####&&&&##&&############@@##@@@@###@@#######@#&&#%%&%$&##%eP$$$%##&$oyCyye%&&&&&$&#$CP&###@#&#@#%osililslssioPyi....iiiiissCyCysy%$#osCe$%$oCtyyyCsll%eP###%$$$PP%&######&%####@#####@@@@#######$P$$P%######%$$eooVe$$$$PeeeP$%%$PVVe$$%$otCPeVysiiiilyCxie$$$PeytCP%############%&#############
...iiiiisoP&#&##&&%&####%&&#&###&&#@#&&%%%############@@@@@###@@########%%&#%%#%PP$%$$%&&$%&$otssyP###$$&$%%%%&e&#@@#$P%$$&%VseylilColisssi..Cl...iiiiiilCCoP$$$$$PyxtCyCsltPellV$%#@@%eCCyeP$%##&#############@@##@#o$&%%$PeP$P%#%o&##$%&&%$PVoVP$%%$PPPooVe$%$eCsyP$eyste$yii...iliCyyCso$&###############$%###@#########
...iiy$%%%&##&##%&%#####&&&#&##&&&###&&%$$$%%&##&&&####@@@@##@@@########&%%&%$%$P$$$$##&$P$%$tlssssCP%%%%###$e%e&####&$PP%%$$PtlsCC$#Pslisi..il..ii..iiiiiiitePoCsCyyCstoxlC$ylle$&###%e$$yCCye$$$##&#####@@@###@###&CP$$%#%PPeePPoC$%%P$%&&%&&$$PeeP$$%%$$$$otCP$$eoyVoyoP$$%eyli..iisyCCyP&######@########P%#############
Clle%&##&%&&#&##&&%#####&&&#&###&&&##&&%$$$$$$$$$%&###@@@@@##@@@#######@##&$$$$%&##%P&%$$PPPPtslliiillso$######e%#######%oyssxCeCiiiixPsisi..i...iy.ii...iiiiilCyyCsyVCoPxilCClle%#@@@@#PyyP%yCCyV$%$$&###@######&%$$t%#&$%$eysiiiiiiy$%%$$$$%&&&&%$$PeeeVyssePPoeyVyyooyVP$$$Peyliili..ilyyyye$#########%Pyye&#@@#######$V
yV$%&&##%%%&#&##&&&#####&&&#####&&###&&&$$$$$$$$$$$%&###@@@@#@@@###########$&&$%#%$PP$$$$PPPPCePyxiiiiiiisy$&#$o$#@@#&$yiiissiC##ysiiiCliVi..yo.....iyi..i..iitsCCllPPxsxslC%ellP%#@@@@@@#%PyCP%PyyyV$$%%#####%%$$%##C$%&%$yCxilyPPxiiisV$%&%$$$%%&&$ysliiiloooCy$PeoyP$$%%$oeyytit$$&yllxP$PesltoP&#####Po$#########&Pyssx
yo$%&%##&%&##&##&&%#####&&&#####&&###&&###&%$$$$$$$$$$$%&####@@@#########&%$%%P$$$$PPPPPPPePPyCCyeeysiiiiiiiixV$##%etsCyi..iiilPPsltoP#&tyi..ii..iy......CV..iiy$oiixxsy$tlxytlsP&#@@@@@@@##&%PoyV%$oooeP%&%$$$%##%%&C$$yiiitV$$$PysiCP#$yCoP%&%PyxiloViiiilssyyyoeePP$%$$eooP%VCxlyP$PP$PytsCCCxillxV%###########$VxssxxtC
yo$%&&##%%%&#&##&&&#####&&&#####&####&&#@@@@##%$$$$$$$$$$$%&######@@##&%%%%$%$PPPPPPPPPPeP$%#oyCsssClCVxiiiiiiiilstyyoyyCsii..iiiiiP&Poylyi..li...i.iyi...i..iisyslle$tyoslsPoss$#@@@@@@@@@@#####$Poo$&PeeP$&#&%%&%$osPotiiloPVCily$##@@#&%PytssiCP&####yCliisxCxyyePVoyxyo$%e$$PoVP$$oCstCyCsiyPyiiiilso$####&PyssstxCe%&%
yo$%&&##&%&&####&&&#####&&&#####&&###&$CC%@@@@@@#&%$$$PPP$$$$$$&#######%$$$PPPPPPeePeP$&##@@@eoP$PoxlsssCixsiiiiiyyyyePPiiilyCii.iiiiiiyPPi..ix..ii..ii..Cl..iixPollyystotly$yss$&%%&##@@@@##@@@####&$PPP%%$%&%$PCy$oC&#&&%eClo$##@@@@@##%esiCP&##%Poy%$xPPy$oliisxCCCoPeoVPPPPP$PoCsCCCxlitsii%&#%eooiiiiilCssstxy$%%&%$$P
yo$%&&##&%&##&##&&&#####&&&#####&##%PCCeee#@@@@@@@@##&$PPPPPPPPPP$$%&%%$PPPePPePeeP$&##@@@@@@PyyCCoPystiiisCyysiiCe$$%$Ptii.iiiCtii..iiilsi..i...iy.ii...il..ilCPCllyVCVPCssCyss$%$&#&$$&#@@###@@@@@#&##%&#&#oii$ey$$$&%$&##&##@@@@##%oCilV%###PCsyP%eP$CCiC%##&$ylisxCCxCyPyP$oCsCCCtlsiilVCii%#%oCo&%$siiiixty$&#&%$%&#&$
yo$%&&##&%&&#&##&&&#####&#&####%eyCyeP$%##%$$&#@@@@@@@##&$PeeeeeeeeVeeVeeeeeeeeP%&#@@@@@@@#&$yP$eCsiixePeiiiiiiliC$PPeeeClytii.iiixCsiiisCi..yy.....iyi..i...ilsCCllPPCttxsy%Pxx%&$%%%&&%$$%&#@@##@@#####@@#@iiiCeP$eyP$P%&$%#@@@##Psiiiy&##%tiiy###$Posiy$%exy%##%Ciise$oCsssxCCtlssiCoiiiliii&##P$P#&Poy$yy%&&%PoP&####%y
yo$%&&##&%&&####&&&#####&###%PyCCy$&%PVCC%@@#&$P$#@@@@@@@@##%$eeeVeeVeeVoVVe$%##@@@@@@@#%PP%#eyVP$$exllssioVtliiiyee$$%$iiiiittii...iiiiy$i..ii..iy......yy..ily%VlltCxy$ysCeCxx&#$&#&%%&####%%&#@@@###@@@@@@l....isoPP$yo$P$&%%###$VoyliilV%&$ysxytiiiyP%$CP%&%esito$%%ePPeyyCsliiVyissiiiyCii&####&##PCs$ePPe%#&%######&y
yV$%&&##&%&#####&&&#####$PoCye$$yy#%eyCyo$%#@@@@#$PP%#@@@@@@@##%PeVooooeP$&&$##@@@@@&$P$&#@@@PooCCyVCyeCliiltoetiy$%%$$PPCii..iisCsii..iyoi..li..il.iyi..ii..ilCytssP$yoeCxCPeCC%%$%#########@#&$P$&#####@@###&C.....iiyeP$yCyClsVylssCoVysiiiCP%%esiiiile%&PCiiye$%$$Pee%$osiiyCiitlilCiiiysii&#######&yxooeeP$%%&&&&%%%yC
yo$%&&##&&&##&##&&&##%PCCye$&#&essyyoeyCsssilV%#@@@#%PP$##@@###P$&&$PP%&%P$#%PeP%%PP$#@@@@@@#ee$PVyCsxCyVsCsiiiiio$PPP$$xilCCsiiiiiiCsiioPsiieo..ii..ii..si..isCeosseeCCoyxo&$ye%%&########&$$&##&%eo$#@@@@@@###l.xi....iitsseP$eoCsyVoyCCyeoCliisV%&$P%%PCiso$$%$$PeP%&$%$esilyliitCiCyiiillii#######esy$$P$$$PP$$$$%%%%$$
yo$%&&##&%&&####&$$PCyeeP$##%PyylCPVyxCP#%%oiiiiC$###&PyP#%%%Pe$$PP%P$$P$$PeP%$%%%#@@@@@##%$PyCCyyPPytCllloPVysiilsy$&&$Ciiiilyysii.iiiiliiiyPVi.iPiii...sC..isy$ossCoyP%yCe%%%$PP%###%%&&##&%#&$$$&#@@@@@@#@##&ii#&C.iiiCeeeyyxyoyoPeCyeVoyCCVVysiiiCylixo$%%$PeP$&&$P$P%PVliilliioCiiiiiiVCii#####@@#&PyyV$$$%$PeP$&&&%%%
yo$%&&##&&&##&%etCye$##PoyyyoPeylsy%&CilCtytiiiiy$CliC%#$eP$Pe$$yVe$%PyCCe%Pe$$Pe%#&##%PeeVeeeeeeyCyxyP$Pttslliiy$$CiisooCoyxiiiiiCyliiiCoi..iilyooiiei..i...isxyyxx$%oP&%$$Peyy$###&%&##&#&%$$&#@###@@#@@@####&iieysCVeeysyyCClCyyeP$eePyyoeooCtyVVyso$%%$$P$$%#$P$P$##$#$VlilVxiiiliCoiiiliii%####@@@#####$yyVP%&%yxe%%%%
yo$%&&##&%$$ysyVeP$##$oCyoPeoCCtisCV$%%oCiePxCssoPCsssCyoP$eoPP%##%%%%PsCePPPy$$PyCoeoVoVoooVee$&%$eyxsCyliise%###&##$yiiiiiCoysiiiiisiiti...Cii.iiyoel..oo..isy%Pty$&%%Peoo$$yCye$&###&&%$%####@@##@@#####&&%$ellVPeyslstCoyyyxCo$%%%PCiiilsxyeooyxxy$PPe$$&%PP%$%#&###%%PVliiliiiVyissiiiyCii%####@@@####@&&&%eyyP$$&&&&&
oo$%&##%ossyV$&&PoyyCyeP$%#iiiiCP%%ytsileyyoyxiillxCtCy$PyyCy$&###P$%%%$%&%$yyoyoPPVyyyoyooooVeP$$%%$oliiy$###%$eoePP$%&%esiiiisyotiiiiii.....i..iiiiislseei.ixV%$$%%$eePoyyoytCCy$#&%$$%####@#@@@@@@@@##%$eClily$CllsCe$osstCCle%$$PPe%$Cli.ioePyyyyooP$&%P$%P#########$#$VliiyCiitlilCiiiysii%###@@@@####@#&#@##%$oyV$%$P
iioeyysCyVP&##%eCCye%#&$$%&i....iiiiiiiiisliilsttsCCCoyyCyPePPV$%&P$%%%%PP$$$$PPPooVPeyyyyyoVVVePVyxily$##&%PoeoxxxlixyVooyy$#Ciiilyoyiii.ii.....ii.iiiiilytile%%$PoePVeeyttCyoeoyP$%&#@@###[email protected]@@@@##@######xiiiisCyyyyeP$P%$yosiCtsty$%ePPPeo$$PyxxCe&&$P$$$########%%##%#$olilysiitCiyoiiillii%###@@@@#&&#@###@#####&$eyo$
i..iso$%PeoPyCCoeP%#@#&$$$%iiii....iiiiiiilsxstCyVoeeoooyyyye%&&#$yP%&&%%&&$$%%$$P$$yCo$PVoyyyCsiisP&##&$yCxtCyxssxsiisCP&#@@@$yCiiiiiiiyiii....i....ii..iiilCeeeeyyeeCCCyyyyyyye$#@@##@@@@#y###@@#$oCsyP%%l..iiiiilsyyyoeP$PyClCiixCsoP$$$PVCsCyCCsV&%$$#&######%######$%PoliilliiVCiiiiilPyil$&##@@@@@###@###@#####&%####
Ciiee%#$ytxCe$&%$$$#%#%$$$$i..ilii.....isslCCyyyoyyVeeeVoClly$#&&%$&##&&&%$$&%P$%%$ee%####$ylily$###%PooeexiiiiiisVsiiy&@@@@@@yisyVysiiio$Cii...ii.......lsi.iCV$eCxtCyyoooyyePe#@@@@@@@@@##[email protected]#%Pyo$$PoiiiseP.....iiiilsxyyyCsP$%[email protected]@@@#######%#####&###$#$VsileCiiliiCeliC%$P$Pe&#@@#@####@###@#&&#@######
..issssxyoe##@#%$$$%%&%$$Peii....iiiii.itxyVVyCyyoVooyyCtCCyy$##&&####&&&%$%#&$PeP%###@#$Cise&##&$oCsliiliixyVxliix&$osilV$%#@$CiiiltssVsiiiePVsi.....ii.....istCCCyyyyyyyP%###P#@@@@##@@@@#CVoVysy$%%[email protected]@@@###%%########%###%&$VsiisiiieoiP$eP$Peyso%#@@@#@@###@###@####@###@##
*/

library MerkleProof {

}

contract VoxelCityPlots is ERC721Enumerable, Ownable {

    ////////////////////////////////////////////////////////////////////////
    //                             VARIABLES                              //
    ////////////////////////////////////////////////////////////////////////
    address private owner_;
    address private cityBank_;
    string public townSquareURI;


    struct Sale {
      string baseURI;
      uint256 tokenSupply;
      uint256 numTokens;
      uint256 id;
      uint256 state; 
      uint256 startWL;
      uint256 endWL;
      uint256 standardPrice;
      uint256 whitelistPrice;


      bytes32 merkleRoot;
    }
    mapping(uint256 => Sale) public saleIdToSale;
    uint256 public  numberOfSales;
    mapping(address => uint256) public mintPerWhitelist;

    mapping(uint256 => uint256) public tokenIdToSale;

    uint256 public activeSaleId;

    ////////////////////////////////////////////////////////////////////////
    //                         MUTATIVE Functions                         //
    ////////////////////////////////////////////////////////////////////////
    
    constructor(address _cityBank, string memory _townSquareURI) ERC721("Voxel City Plots", "VCP") {
        cityBank_ = _cityBank;
        townSquareURI = _townSquareURI;
        numberOfSales = 0;
        _safeMint(msg.sender, 0);
    }

    // create new sale 
    function CreateSale(string memory _baseURI, uint256 _tokenSupply, bytes32 _merkleRoot, uint256 _maxPerWhitelist, uint256 _startWL, uint256 _standardPrice, uint256 _whitelistPrice) public onlyOwner{
      require(_tokenSupply>0,"Token supply must be a positive integer");
      Sale memory sale;
      // get number of sales 
      uint256 saleId = numberOfSales;
      sale.baseURI = _baseURI;
      sale.tokenSupply = _tokenSupply;
      sale.state = 0;
      sale.id = saleId;
      sale.merkleRoot = _merkleRoot;
      sale.endWL = _startWL+_maxPerWhitelist;
      sale.startWL = _startWL;
      sale.standardPrice = _standardPrice;
      sale.whitelistPrice = _whitelistPrice;
      sale.startWL = _startWL;
      saleIdToSale[saleId] = sale;
      numberOfSales = numberOfSales + 1;
    }

    function StartPresale(uint256 _saleId) public onlyOwner{
       require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
       require(saleIdToSale[_saleId].state != 2, "Sale is already in active");
       require(saleIdToSale[_saleId].state != 3, "Its already sold out");
       saleIdToSale[_saleId].state = 1;
    }

    function StartSale(uint256 _saleId) public onlyOwner{
       require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
       require(saleIdToSale[_saleId].state != 3 , "Its already sold out");
       saleIdToSale[_saleId].state = 2;
    }

    function EndSale(uint256 _saleId) public onlyOwner{
       require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
       require(saleIdToSale[_saleId].state != 3 , "Its already sold out");
       saleIdToSale[_saleId].state = 3;
    }

    function MintPlot( uint256 _saleId, uint256 _numberOfTokens) public payable {
        require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
        require(saleIdToSale[_saleId].state == 2, "Sale is not active!");
        require(_numberOfTokens > 0, "Can't mint a non-positive number of tokens!");
        require(getNumLeft(_saleId) > 0, "No plots left to mint!");
        require(msg.value == (saleIdToSale[_saleId].standardPrice * (_numberOfTokens)), "Ether value sent is not correct");
        for(uint256 i = 0; i < _numberOfTokens; i++) {
            if (saleIdToSale[_saleId].numTokens < saleIdToSale[_saleId].tokenSupply) {
                uint256 tokenId = totalSupply();
                uint256 saleTokenId = saleIdToSale[_saleId].numTokens;
                _safeMint(msg.sender, tokenId);
                saleIdToSale[_saleId].numTokens = saleIdToSale[_saleId].numTokens + 1;
                tokenIdToSale[tokenId] =  _saleId<<64 | saleTokenId;
            } else {
                payable(cityBank_).transfer((_numberOfTokens - i) * saleIdToSale[_saleId].standardPrice);
                return;
            }
        }
        payable(cityBank_).transfer(msg.value);
    }

    function MintWhitelisted( uint256 _saleId, uint256 _numberOfTokens, bytes32[] calldata merkleProof,uint256 index) public payable {
        require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
        require(saleIdToSale[_saleId].state == 1, "Sale is not active");
        require(_numberOfTokens > 0, "Can't mint a non-positive number of tokens");
        require(getNumLeft(_saleId) > 0, "No plots left to mint!");
        require(msg.value == (saleIdToSale[_saleId].whitelistPrice * (_numberOfTokens)), "Ether value sent is not correct");

        require(verify(merkleProof, saleIdToSale[_saleId].merkleRoot,  keccak256(abi.encodePacked(msg.sender)), index), "Invalid proof");

        uint256 startWL =saleIdToSale[_saleId].startWL; 

        if(mintPerWhitelist[msg.sender] > startWL){
          startWL = mintPerWhitelist[msg.sender];
        }
        require(startWL + _numberOfTokens <=saleIdToSale[_saleId].endWL, "The number of whitelisted mints is limited per wallet");

        for(uint256 i = 0; i < _numberOfTokens; i++) {
            if (saleIdToSale[_saleId].numTokens < saleIdToSale[_saleId].tokenSupply) {
                uint256 tokenId = totalSupply();
                uint256 saleTokenId = saleIdToSale[_saleId].numTokens;
                _safeMint(msg.sender, tokenId);
                saleIdToSale[_saleId].numTokens = saleIdToSale[_saleId].numTokens + 1;
                tokenIdToSale[tokenId] =  _saleId<<64 | saleTokenId;
            } else {
                payable(cityBank_).transfer((_numberOfTokens - i) * saleIdToSale[_saleId].whitelistPrice);
                return;
            }
        }
        mintPerWhitelist[msg.sender] = startWL + _numberOfTokens;
        payable(cityBank_).transfer(msg.value);
    }
    function getNumLeft(uint256 _saleId) public view returns (uint256){
        require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
        return saleIdToSale[_saleId].tokenSupply - saleIdToSale[_saleId].numTokens;
    }

    function setBaseURI(uint256 _saleId, string memory _newURI) public onlyOwner {
        require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
        saleIdToSale[_saleId].baseURI = _newURI;
    }

    /* ========== VIEWS ========== */

    function price(uint256 _saleId, uint256 _count) public view returns (uint256) {
        require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
        return saleIdToSale[_saleId].standardPrice * _count;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(tokenId == 0) return townSquareURI;
        uint256 saleId  = tokenIdToSale[tokenId]>>64;
        uint256 saleTokenId = tokenIdToSale[tokenId]&((1<<64)-1);
        Sale memory sale = saleIdToSale[saleId];
        return (bytes(sale.baseURI).length > 0 )? string(abi.encodePacked(sale.baseURI, uint2str(saleTokenId))) : "";
    }

    function saleTokenURI(uint256 _saleId, uint256 _saleTokenId) public view returns (string memory) {
        require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
        require(saleIdToSale[_saleId].numTokens > _saleTokenId, "Sale token id does not exist");
        Sale memory sale = saleIdToSale[_saleId];
        return (bytes(sale.baseURI).length > 0 )? string(abi.encodePacked(sale.baseURI, uint2str(_saleTokenId))) : "";
    }

  function uint2str(uint _i) public pure returns (string memory _uintAsString) {
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

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint index
    ) internal pure returns (bool) {
        bytes32 hash = leaf;

        for (uint i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == root;
    }
    function hashVal(string memory val) public pure returns(bytes32){
      return keccak256(abi.encodePacked(val));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}