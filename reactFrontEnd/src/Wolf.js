import React, { useEffect, useState } from "react";
import { BigNumber, ethers } from "ethers";
import './App.css';
import abi from '../src/artifacts/contracts/PixelSheep.sol/PixelSheep.json';

import fabi from '../src/artifacts/contracts/FLCE.sol/FLCE.json';
import pabi from '../src/artifacts/contracts/Pot.sol/Pot.json';

import toabi from '../src/artifacts/contracts/Toke.sol/Toke.json';
import lpabi from '../src/artifacts/contracts/LPToke.sol/LPToke.json';

import wabi from '../src/artifacts/contracts/Wolf.sol/Wolf.json';
import vabi from '../src/artifacts/contracts/Vote.sol/Vote.json';
import tabi from '../src/artifacts/contracts/Timer.sol/Timer.json';
import aabi from '../src/artifacts/contracts/AddressManager.sol/AddressManager.json'

import minting from './minting.gif';

const hasvote = false;

///todo
// approve entire balance of user


/////////////////////////////////////////
// vars that need altering for deployment
/////////////////////////////////////////
// mint passes generated for premint phase
var track = 0;
const mintPasses = {
  '0': {
    mintPass: {
      message: '0x0000000000000000000000000000000000000000',
      r: '0x0000000000000000000000000000000000000000000000000000000000000000',
      s: '0x0000000000000000000000000000000000000000000000000000000000000000',
      v: 0
    }
  },
  
};

var pixelsheepContractAddress;
var sheepContractAddress;
var wolfContractAddress = "0xd6BDDBfE900E156B1657B4078fFa6608Ac1106B2";
var timerContractAddress = "0x2929e9FB17C54E6f1C3f7eE63f2f624830DDC3e4";
const voteAddress = "0xE5a8D92E3AC460819cA130CC0512E318aE5075F9"; //PRIVATE NTE
var addressManagerContractAddress="0xefB97c29820F026311a0B6BCBAaCd87ae93dC509";

const targ = "private";
var targetChainId;
var chainParams;
if(targ == "private"){
    contractAddress = "0x0000000000000000000000000000000000000000";//private
    pixelContractAddress = "0x0000000000000000000000000000000000000000";
   targetChainId = 0;
   chainParams = {
                        chainId: "0x00",
                        rpcUrls: ["https://rpc"],
                        chainName: "main net",
                        nativeCurrency: {
                            name: "",
                            symbol: "",
                            decimals: 18
                        }
                      };
}else if (targ =="test"){
    contractAddress = "0x0000000000000000000000000000000000000000";//test
    pixelContractAddress = "0x0000000000000000000000000000000000000000";
   targetChainId = 0;
   chainParams = {
                        chainId: "0x00",
                        rpcUrls: ["https://rpc"],
                        chainName: "main net",
                        nativeCurrency: {
                            name: "",
                            symbol: "",
                            decimals: 18
                        }
                      };

}else{
    contractAddress = "0x0000000000000000000000000000000000000000";//main
    pixelContractAddress = "0x0000000000000000000000000000000000000000";
   targetChainId = 0;
   chainParams = {
                        chainId: "0x00",
                        rpcUrls: ["https://rpc"],
                        chainName: "main net",
                        nativeCurrency: {
                            name: "",
                            symbol: "",
                            decimals: 18
                        }
                      };                    
}
  var maxPerWallet = 1; // updated in getOwned
  ///////////////////////////////////////////////////////////////////////const




  export default function App() {

  const [errorMsg, setErrorMsg] = useState("");
  const [voteMsg, setVoteMsg] = useState("");
  const [hideButton, toggleButton] = useState(false);

  /*image placeholder for owned NFT / title to show supply*/
  const [imageurl, setImageURL] = useState("");
  const [visibleTitle, setVisibleTitle] = useState("");
  const [nftName, setNftName] = useState("");
  const [price, setPrice] = useState("");

  const [voteAvailable, setVoteAvailable] = useState(false);

  const [imagesSheep, setImageURLsSheep] = useState([]);
  const [imagesWolf, setImageURLsWolves] = useState([]);
  const [namesSheep, setNamesSheep] = useState([]);
  const [namesWolf, setnamesWolf] = useState([]);
  /*store user public key*/
  const [currentAccount, setCurrentAccount] = useState("");

  //UI for #
  const [mintAmount, setMintAmount] = useState(1);
  const handleMintAmount = event => {
    if(parseInt(event.target.value) > maxPerWallet){
      setMintAmount(maxPerWallet);
      event.target.value = maxPerWallet;
    }else if(parseInt(event.target.value) <= 0){
      setMintAmount(1);
      event.target.value = 1;
    }else
      setMintAmount(parseInt(event.target.value));
   
  };

  const contractABI =  abi.abi;
  const voteabi =  vabi.abi;
  const wolfABI = wabi.abi;
  const timerABI = tabi.abi;
  const amABI = aabi.abi;
  const FLCEABI = fabi.abi;
  const potABI = pabi.abi;
  const tokeABI = toabi.abi;
  const LPABI = lpabi.abi;

  /* check for MMask and correct Chain*/
  const checkIfWalletIsConnected = async () => {
    try {
      const { ethereum } = window;
      if (!ethereum) {
        setErrorMsg("error : MetaMask is required to mint Sheep");
        console.log("make sure you have metamask");
        toggleButton(false);
        
      } else {
        console.log("allright");
        setErrorMsg("");
        toggleButton(true);
      }
      /*check authorization to access user wallet*/
      const accounts = await ethereum.request({method: "eth_accounts"});
      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Connected account:", account);
        setCurrentAccount(account)
        const chainIda = await ethereum.request({method: "eth_chainId"})
        console.log("Current Network:", chainIda)
        if ( parseInt(chainIda,16) == targetChainId){
          console.log("Correct Chain"); // show button
          setErrorMsg("");
          toggleButton(true);
        }else{
          setErrorMsg("error : Please select the  Mainnet as your current wallet chain");
          console.log("Incorrect Chain");
           toggleButton(false);
          //button to activate this
          
          const chainIdb = await ethereum.request({ //////////////////MUST UPDATE FOR PRODUCTION
            method: "wallet_addEthereumChain",
            params: [chainParams]
          })

          checkIfWalletIsConnected(); //maybe page refresh isntead?
          
        }
        // show last text on UI everytime <---what?
        const callgetSupply = getSupply();
      } else {
        //setErrorMsg("No authorized account found");
        console.log("No authorized account found")
      } 
    } catch (error) {
      console.log(error);
    }
  }


  /* connect to MetaMask */
  const connectWallet = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        alert("Get MetaMask!");
        return;
      }

      const accounts = await ethereum.request({ method: "eth_requestAccounts" });

      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts[0]);
      const callgetSupply= getSupply();
    } catch (error) {
      console.log(error)
    }
  }

  /* get  stats on how many NFTs are available */
  const getSupply = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(sheepContractAddress, contractABI, signer);
        
        // retrieve, calculate supply, and display 
        let result = await nftContract.howMany();
        let cost = await nftContract.cost();
        setPrice(cost / 10**18); 
        const { 0:maxSupply, 1:remaining, 2:burnt} = result;
        let supplyRemaining = remaining-burnt + " out of " + maxSupply + " left to mint";
        console.log("burnt : " + burnt);
        setVisibleTitle(supplyRemaining);
        await supplyRemaining.wait;

  //DO wolves here too
        let paused = await nftContract.paused();
        if(paused)
          setErrorMsg("contract paused");

        //determine if wallet has NFTs already to load in NFT on wallet connect
        getOwned();

      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
    }
  }

  const getWolfSupply = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);
        
        // retrieve, calculate supply, and display 
        let result = await nftContract.howMany();
        let cost = await nftContract.cost();
        setPrice(cost / 10**18); 
        const { 0:maxSupply, 1:remaining} = result;
        let supplyRemaining = remaining + " out of " + maxSupply + " left to mint";
        setVisibleTitle(supplyRemaining);
        await supplyRemaining.wait;

        let paused = await nftContract.paused();
        if(paused)
          setErrorMsg("contract paused");

        //determine if wallet has NFTs already to load in NFT on wallet connect
        getOwned();

      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
    }
  }

  const mintOne = async (mintType) => {
    try {
      const { ethereum } = window;
      if (ethereum) {    
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        var nftContract;
        if (mintType == 'sheep')
          nftContract = new ethers.Contract(sheepContractAddress, contractABI, signer);
        else if(mintType == 'wolf')
          nftContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);

        setErrorMsg("verifying: ");
        //VERIFICATION B4 MINT/////////////////////////
        console.log("====VERIFICATION===");
        toggleButton(false);

        setErrorMsg("verifying: active contract");
        let paused = await nftContract.paused();
        if(paused) {
          setErrorMsg("error : Contract is Paused, please check discord for more info");
          throw "Contract Paused.";
        }
        
        setImageURL(minting); // loading image
        const checksumAccount = await ethers.utils.getAddress(currentAccount);        
        
        setErrorMsg("verifying: Address");
        // CHECK IF whitelist event
        // CHECK IF Wallet address exists in MINTPASS list
        // Store appropriate mintPass  for submission with Mint request     
        let onlyWhitelisted = await nftContract.onlyWhitelisted();
        if( onlyWhitelisted ){
          if(checksumAccount in mintPasses == false) {
            setErrorMsg("error: Address not approved for Premint");
            throw "No Valid MintPass for this Address.";
          }
          var mintPass = mintPasses[checksumAccount];
        }else{
          var mintPass = mintPasses['0'];
        }
       
        setErrorMsg("verifying: Mint Supply");
        // CHECK # of sheep trying to mint
        let mintMax = await nftContract.maxMintAmount();
        console.log(mintMax);
        if(mintAmount > mintMax) {
          setErrorMsg("error: You can't mint this many " + mintType + " in a single transaction.");
          throw "Minting too many " + mintType;
        }
        console.log("Max" + mintType + " Per Transaction Check : Pass");

        //CHECK Supply left
       
  console.log('pass');
        var nftLeft;
        if(mintType == 'sheep'){
          let result = await nftContract.howMany();
          const { 0:maxSupply, 1:remaining, 2:burnt} = result;
          nftLeft = remaining-burnt;
        }else{
          let maxSupply = await nftContract.maxSupply();
          let total = await nftContract.totalSupply();
          nftLeft = maxSupply - total;
        }
          
        if(nftLeft = mintAmount < 0 ) {
          setErrorMsg("error: Not enough" + mintType + " left.");
          throw "Sheep all gone.";
        }
        console.log("Supply Check : Pass");
    
        // CHECK IF wallet has max allowed sheep
        let maxPerWallet = await nftContract.nftPerAddressLimit();
        let walletOwnedNFT = await nftContract.addressMintedBalance(checksumAccount);
        if( parseInt(walletOwnedNFT) + parseInt(mintAmount) > parseInt(maxPerWallet) ){
          setErrorMsg("error: Max "+ mintType + " in wallet will be exceeded.");
          throw "Max "+ mintType + " in wallet will be exceeded."
        }
        console.log("Max "+ mintType + " in Wallet Check : Pass");

        setErrorMsg("verifying:  Balance");
        //get cost / set price / mint
        let price = await nftContract.cost();
        await price.wait;
        let totalCost = price.mul(mintAmount);
        const overrides = {value: totalCost,}
        let Balance = await provider.getBalance(currentAccount);
        if( Balance < price * mintAmount ){
          setErrorMsg("error: Not enough funds");
          throw "Not enough funds."
        }
        console.log("Balance Check : Pass");
        console.log("===============");

        setErrorMsg("Please Approve Transaction in your Metamask Wallet");
        var mintresult = await nftContract.mint(mintPass.mintPass, mintAmount, overrides);
        setErrorMsg("...minting...");
        console.log("minting nft...")
        await mintresult.wait();
        console.log("Minted --", mintresult.hash);

        toggleButton(true);
        setErrorMsg("Success!");
        //refresh display to show NFT image
        const callgetSupply = getSupply();
      } else {
        console.log("Ethereum object doesn't exist!");
        setImageURL("");

        
      }
      

      
    } catch (error) {
      console.log(error)
      setImageURL("");
      toggleButton(true);
      //setErrorMsg("error: " + error);
    }
  }

  //update on metamask changes
  useEffect(() => {
    if(window.ethereum) {
      
      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      })
      window.ethereum.on('accountsChanged', () => {
        window.location.reload();
      })

      window.ethereum.on('requestAccounts', () => {
        window.location.reload();
      })
    
      checkIfWalletIsConnected();
    }
  }, [])


  /* display image of NFT owned by signer -- need to account for multiple */
  const getOwned = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        
        setImageURLsSheep((imagesSheep) => []);
        setImageURLsWolves((imagesWolf) => []);

        if(targ != 'test'){
          const pixelContract = new ethers.Contract(pixelsheepContractAddress, contractABI, signer);      
          const pixelResult = await pixelContract.walletOfOwner(signer.getAddress());
          console.log(pixelResult);
          for(var i=0; i<pixelResult.length; i++){
            if(pixelResult[i]){    
            console.log(pixelResult[i].toNumber())     ;
              // returns metadata json of NFT and sets imageurl state
              const meta = await getMeta('pixel', pixelResult[i].toNumber());
              await meta.wait;
              console.log(meta);
              setImageURLsSheep((imagesSheep) =>[...imagesSheep, meta.image]);
              setNamesSheep((namesSheep) =>[...namesSheep, meta.name]);
            }
          }
        }

        const nftContract = new ethers.Contract(sheepContractAddress, contractABI, signer);        
        // returns tokenIDs of owned NFT
        const result = await nftContract.walletOfOwner(signer.getAddress());
        maxPerWallet = await nftContract.nftPerAddressLimit();
        for(var i=0; i<result.length; i++){
          if(result[i]){         
            // returns metadata json of NFT and sets imageurl state
            const meta = await getMeta('golden', result[i].toNumber());
            await meta.wait;
            setImageURLsSheep((imagesSheep) =>[...imagesSheep, meta.image]);
            setNamesSheep((namesSheep) =>[...namesSheep, meta.name]);
          }
        }

         const wolfContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);        
        // returns tokenIDs of owned NFT
        const wresult = await wolfContract.walletOfOwner(signer.getAddress());
  //whats this doing here?????

        maxPerWallet = await wolfContract.nftPerAddressLimit();

        for(var i=0; i<wresult.length; i++){
          if(wresult[i]){      

            console.log(wresult[i]);

            // returns metadata json of NFT and sets imageurl state
            const meta = await getMeta('wolf', wresult[i].toNumber());
            await meta.wait;
            setImageURLsWolves((imagesWolf) =>[...imagesWolf, meta.image]);
            setnamesWolf((namesWolf) =>[...namesWolf, meta.name]);
          }
        }


        isVote();
        //if(result.length > 0 && hasvote){
        if(result.length > 0 && hasvote){
          setVoteAvailable(true);
        }else{
          setVoteAvailable(false);
        }
        console.log('v');
        
        //remove mint button if max owned
        if(result.length >= maxPerWallet){
          toggleButton(false);
        }
        
      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve wallet info");
      }
    } catch (error) {
      console.log(error)
    }
    
  }
  const getWolfOwned = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        
        setImageURLsWolves((imagesWolf) => []);

        if(targ != 'test'){
          const wolfContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);      
          const wolfResult = await wolfContract.walletOfOwner(signer.getAddress());
          console.log(wolfResult);
          for(var i=0; i<wolfResult.length; i++){
            if(wolfResult[i]){    
            console.log(wolfResult[i].toNumber())     ;
              // returns metadata json of NFT and sets imageurl state
              const meta = await getMeta('wolf', wolfResult[i].toNumber());
              await meta.wait;
              console.log(meta);
              setImageURLsWolves((imagesWolf) =>[...imagesWolf, meta.image]);
              setnamesWolf((namesWolf) =>[...namesWolf, meta.name]);
            }
          }
        }

  /*
  //NEED BUT CHANGE TO WOLF  BUTTON

        //remove mint button if max owned
        if(wolfResult.length >= maxPerWallet){
          toggleButton(false);
        }
  */      
      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve wallet info");
      }
    } catch (error) {
      console.log(error)
    }
    
  }


  /* returns metadata json from tokenID */
  const getMeta = async (sheepType, i) => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();

        if(sheepType == 'golden'){
          const nftContract = new ethers.Contract(sheepContractAddress, contractABI, signer);

          // gets metadata from ARWEAVE and reads JSON
          const uri = await nftContract.tokenURI(i);
          const m = fetch(uri,{         
          })
          .then(function(response){
            return response.json();
          })
          .then(function(meta) {
            return meta;  
            
          });  
          return m;  
          
        }else if (sheepType == 'pixel' && targ != 'test'){
          const pixelContract = new ethers.Contract(pixelsheepContractAddress, contractABI, signer);

          // gets metadata from IPFS and reads JSON
          const uri = await pixelContract.tokenURI(i);
          const m = fetch(uri,{  
            headers : { 
              'Content-Type': 'application/json',
              'Accept': 'application/json'
             }       
          })
          .then(function(response){
            return response.json();
          })
          .then(function(meta) {
            return meta;  
            
          });    
          return m;
        
                     
      }else if (sheepType == 'wolf'){
          const wolfContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);
          console.log("tokwn" + i);
          // gets metadata from IPFS and reads JSON
          

/*
          const st = await wolfContract.wolfState(i);
          console.log(st);
*/  
          const st = await wolfContract.wolves(i-1);
          console.log(st);

          const bs = await wolfContract.wolfBaseURI(st.wolfState);
          console.log(bs);

          const uri = await wolfContract.tokenURI(i);
          console.log(uri);
          const m = fetch(uri,{ 

            })
          .then(function(response){
            return response.json();
          })
          .then(function(meta) {
            return meta;  
            
          });    
          return m;
        }

        
              
      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve Metadata");
      }
    } catch (error) {
      console.log(error)
      setErrorMsg("Cannot retrieve Metadata");
    }
  }


  //FLCEEEE
  const claimFLCE = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        
          const wolfContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);      
          const wolfResult = await wolfContract.claimFLCE();
          console.log(wolfResult);
          
      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve wallet info");
      }
    } catch (error) {
      console.log(error)
    }
    
  }


 //▀█▀ █▀▀ █▀ ▀█▀ █ █▄░█ █▀▀
 //░█░ ██▄ ▄█ ░█░ █ █░▀█ █▄█

const potContractAddress = '0x762C322190F18956D6C439746938cEeDeA3D15DC';
timerContractAddress = '0x2929e9FB17C54E6f1C3f7eE63f2f624830DDC3e4';
const FLCEContractAddress = '0x14907212241D43D10ABA3e26A067AB6ACD6E4B17';
wolfContractAddress = '0xd6BDDBfE900E156B1657B4078fFa6608Ac1106B2';

const testing = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();

        const TokeCA = "0x9f96101E37ac0F1929807e44d25643D7D9F4407f";
        const LPCA = "0x2f9dC371F1A5f76fCd98fF81BC0677B771c1b36c";



sheepContractAddress = '0xD8b23602F6b45453B9cca56a85603aE9D23CCd62';
        const sheepContract = new ethers.Contract(sheepContractAddress, contractABI, signer);
        const wolfContract = new ethers.Contract(wolfContractAddress, wolfABI , signer);   
        const tContract = new ethers.Contract(timerContractAddress, timerABI, signer);
        const aContract = new ethers.Contract(addressManagerContractAddress, amABI, signer);
        const fContract = new ethers.Contract(FLCEContractAddress, FLCEABI, signer);
        const pContract = new ethers.Contract(potContractAddress, potABI, signer);
        const tokeContract = new ethers.Contract(TokeCA, tokeABI, signer);
        const LPContract = new ethers.Contract(LPCA, LPABI, signer);
        console.log(await aContract.contractAddress('wolf'));
        console.log(await aContract.contractAddress('timer'));
        console.log(await aContract.contractAddress('FLCE'));
        console.log(await aContract.contractAddress('pot'));
        console.log(await wolfContract.contractAddress('FLCE'));
        console.log(await fContract.contractAddress('wolf'));
        console.log(await fContract.contractAddress('pot'));

      //await aContract.setAndPush(['wolf','FLCE','pot','timer'],[wolfContractAddress,FLCEContractAddress,potContractAddress,timerContractAddress]);
      //console.log(await sheepContract.setWolfContract(wolfContractAddress));

        console.log("POT: "+ethers.utils.formatEther(await pContract.getPotBalance()));
        console.log("POOL: "+ethers.utils.formatEther(await pContract.getPoolBalance()));
        console.log("my FLCE Balance: "+ethers.utils.formatEther(await fContract.balanceOf(signer.getAddress())));
        console.log("FLCE AVAIL: "+ethers.utils.formatEther(await fContract.FLCEClaimable()));
        console.log("FLCE OUT: "+ethers.utils.formatEther(await fContract.FLCEOutstanding()));

        console.log("living Wolves : " + (await wolfContract.livingWolfCount()));
        console.log("minted Wolves : " + (await wolfContract.totalMinted()));
        console.log("current Week : " + (await wolfContract.currentWeek()));
        console.log("hw1 : " + (await wolfContract.healthyWolves(1)));
        console.log("hasWolfClaimed : " + (await wolfContract.hasWolfClaimed(1)));
        console.log("hw2 : " + (await wolfContract.walletOfOwner("0x9dc905a1c270a01651046e6f68b30784b1a70335")));
        console.log("hasWolfClaimed : " + (await wolfContract.hasWolfClaimed(2)));

        console.log("weekly Timer exp : " + await tContract.isWeeklyTimerExpired());     
        console.log("game Timer exp : " + await tContract.isGameTimerExpired());
        console.log("weekly timer : " + (await tContract.getWeeklyTimer()).toNumber());
        let cw = await wolfContract.currentWeek();
        console.log("Hungry This week : " + (await wolfContract.hungryWolvesThisWeek(cw)).toNumber());
        console.log("# fed wolves : " + (await wolfContract.wolfStateCounts(3)).toNumber());

        let wolf0 = await wolfContract.wolves(0);
        console.log("WOLF 1+++++++++++");
        console.log(wolf0);
        console.log("AllottedFLCE "+ wolf0.tokenId + " : " + wolf0.allottedFLCE.toNumber());
        console.log("1 needs to eat : " + wolf0.needsToEatAmount);
        console.log("stats: " + wolf0.stats);
        console.log("state: " + wolf0.wolfState);
        console.log("last week updated : " + (await wolfContract.lastWeekUpdated(1)).toNumber());

         console.log("WOLF 2+++++++++++");
        let wolf1 = await wolfContract.wolves(1);
        console.log(wolf1);
        console.log("AllottedFLCE "+ wolf1.tokenId + " : " + wolf1.allottedFLCE.toNumber());
        
        console.log("2 needs to eat : " + wolf1.needsToEatAmount);
        console.log("stats: " + wolf1.stats);
        console.log("state: " + wolf1.wolfState);
        console.log("last week updated : " + (await wolfContract.lastWeekUpdated(2)).toNumber());

        console.log("state counts: " + await wolfContract.wolfStateCounts(3) + " "+ await wolfContract.wolfStateCounts(2) + " "+ await wolfContract.wolfStateCounts(1) + " "+ await wolfContract.wolfStateCounts(0));
        
        console.log("total healthy wolf sats : " + (await wolfContract.totalHealthyWolfStats()).toNumber());
    //Wen new contract++++++   
        //mint
        //await wolfContract.startWolfLifeCycle();
//FAILS AFTER FEEDING SHEEP
        await wolfContract.getMaFLCE(); 

        //await fContract.feedFLCE(1, BigNumber.from("10"));

        //await tContract.weekResetForTesting();
        //await wolfContract.eatSheep(2,6); 
        //console.log("weekly FLCE available: " + (await wolfContract.totalWeeklyFLCEAvailable()).toNumber());
        //console.log("living Wolves: " + (await wolfContract.livingWolfCount()).toNumber());
///deadwolves getr no flce. why are they being allottedFLCE?

//why is this comiung bacl as hex? PROBLEM IN CALC ALLOTED FLCE
/*
        console.log((await wolfContract.allottedFLCE(1)).toNumber());
        console.log((await wolfContract.allottedFLCE(2)).toNumber());
        console.log((await wolfContract.allottedFLCE(3)).toNumber());
        console.log((await wolfContract.wolfState(1)).toNumber());
        console.log((await wolfContract.wolfState(2)).toNumber());
        console.log((await wolfContract.wolfState(3)).toNumber());
        console.log((await wolfContract.wolfStats(1)).toNumber());
        //console.log((await wolfContract.wolfState(4)).toNumber());
        //console.log(await wolfContract.claimFLCE());
        //console.log((await wolfContract.healthyWolves(3)));
        //console.log("FLCE outstanding: " + (await fContract.FLCEOutstanding()));
*/
//IF CHANGE POT
        //await tokeContract.approve(potContractAddress, BigNumber.from("100000000000000000000"));
        //xxxawait pContract.fillPool(BigNumber.from(BigNumber.from("100000000000000000000")));
        //await pContract.fillFakePot(BigNumber.from(100));


/*
          const aContract = new ethers.Contract(addressManagerContractAddress, amABI, signer);                     
          const aResult = await aContract.setAddress('addressManager','0x4Dc9Af65618045c8fB0ec1Eb472A9d802fD2155f');
          const aaResult = await aContract.contractAddress('addressManager');
          //0xb003c6aDfEA59F47CFDD8D87321E755D66a701D3
          console.log(aaResult);
/*

const potABI = pabi.abi;
          const ccc = new ethers.Contract("0x5c3B93780AC453E40B40229AbBC55993A067717e", potABI, signer);                     
          //const xxx = await ccc.setAddress('wolf','0xb003c6aDfEA59F47CFDD8D87321E755D66a701D3');
          const rrr = await ccc.AcontractAddress('wolf');
          //0xb003c6aDfEA59F47CFDD8D87321E755D66a701D3
          console.log(rrr);

/*
console.log(wolfContractAddress);
          
          const wolfContract = new ethers.Contract(wolfContractAddress, wolfABI, signer);                     
          const wolfResult = await wolfContract.startWolfLifeCycle();
          console.log(wolfResult);
          

         
          const timerContract = new ethers.Contract(timerContractAddress, timerABI, signer);
           const timerResult = await timerContract.setWolfContractAddress(wolfContractAddress);
          console.log(timerResult);
        */

      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve wallet info");
      }
    } catch (error) {
      console.log(error)
    }
    
  }


  /*------------------VOTE-------------*/
const isVote = async() =>{
   try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const voteContract = new ethers.Contract(voteAddress, voteabi, signer);
               
        let hasvote = await voteContract.activeVote();
        console.log("hasvote: " + hasvote);        
        setVoteAvailable(hasvote);
        let ipnum = await voteContract.IPNum();
        console.log("ipnum: " + ipnum); 

        //let result = await voteContract.newVote();
        //console.log(result);

        //let vresult = await voteContract.toggleVote(false);
        //console.log(vresult);
/*
        let ipnum = await voteContract.IPNum();
        console.log("ipnum: " + ipnum); 

       let jv = await voteContract.numVotesCast();
        console.log("jv: " + jv);        
       

        let r = await voteContract.getVoteResult(2);
        const { 0:addresses, 1:tokenIds, 2:votes} = r;
        console.log(addresses);
        console.log(votes);
*/
      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
      setVoteMsg("Error Voting: Do you have sheep that are eligible to vote?");
    }
  }

function vote(){}



  const castVote = async (myVote) => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const voteContract = new ethers.Contract(voteAddress, voteabi, signer);

        setVoteMsg("Please Approve Transaction in your MM Wallet");

       
       if(myVote == "x"){

          let result = await voteContract.IPNum();
          console.log(result);
/*
          let av = await voteContract.activeVote();
          console.log(av);

          let r = await voteContract.getVoteResult(2);
          const { 0:addresses, 1:tokenIds, 2:votes} = r;
          console.log(addresses);
          console.log(votes);
*/
          //let nresult = await voteContract.newVote();
          //console.log(nresult);
        }else{
          console.log(myVote);
          let result = await voteContract.castVote(myVote);
          console.log(result);

          let vcnt = result / 10**18;

          setVoteMsg("Vote cast. Your baahh has been herd");
        }
         
      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
      setVoteMsg("Error Voting: Do you have sheep that are eligible to vote?");
    }
  }

 /*
 
 const unPause = async () => {
    try {

      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(sheepContractAddress, contractABI, signer);
       
       //let cost = await nftContract.maxMintAmount(); 
       //console.log(cost);
        // retrieve, calculate supply, and display 
       //let result = await nftContract.pause(false);
       //let pa = await nftContract.paused(); 
       //console.log("paused: " + pa);
       await nftContract.pause(false);
       //let price = BigNumber.from('10000000000000000');
       //await nftContract.setCost(price);
       


      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
    }
  }

  const trans = async () => {
    try {

      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(sheepContractAddress, contractABI, signer);
        
        // retrieve, calculate supply, and display 
        let result = await nftContract.transferFrom("0xda94d833A17783307240d7Eb994eCaECF866624B","0x0244Cb93290142bB1281297cA64012d4364eF812",18);

       

      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
    }
  }


*/
/*
var stats = [];
var md;
$.getJSON("./asset-data/metaDataComplete.json", function(data){
        metaData = data;

      });
$.getJSON("asset-data/_counterStats.json", function(data){
        $.each( data, function( key, val ) {
          stats[key] = [];
          $.each( data[key], function( k, v ) {
            stats[key][k] = v
          });
        });

      });
*/

/////////////////////////////////////////////////////////////////////// TEST AREA
/*
const FLCEsheepContractAddress= "0x0C9a6880a2E73b904FD6efb488e061f85e74d553";
const flceabi =  fabi.abi;
const potAddress = "0xEb9E848756bf7e2F12ea250cBF6443a9FE6C63e2";
const potabi =  pabi.abi;
const tokeAddress = "0x9f96101E37ac0F1929807e44d25643D7D9F4407f";
const tokeabi =  tabi.abi;
const lptokeAddress = "0x2f9dC371F1A5f76fCd98fF81BC0677B771c1b36c";
const lptokeabi =  labi.abi;


const pot = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const FLCEContract = new ethers.Contract(FLCEsheepContractAddress, flceabi, signer);
        console.log('1');
       
        
        let price = BigNumber.from('10000000000000000000');
        const potContract = new ethers.Contract(potAddress, potabi, signer);

        let bresult = await potContract.getPotBalance();
        console.log("balance of pot : " + bresult);
        let presult = await potContract.getPoolBalance();
        console.log("balance of pool : " + presult);

        //const overrides = {value: price,};
        ////NEEDS TO APPROVE?

        //let result = await potContract.fillPot(price);        
        //console.log(result);


        let available = await FLCEContract.FLCEOutstanding();
        console.log("FLCE available " + available/ (10**18));

        let poolBalance = await FLCEContract.getPoolBalance(); 
        console.log("Pool available " + poolBalance/ (10**18));
       // console.log("swap          " + payout/ (10**18));
        

      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
    }
  }


const approve = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const lpTokeContract = new ethers.Contract(lptokeAddress, lptokeabi, signer);

        let price = BigNumber.from('10000000000000000000');

        let result = await lpTokeContract.approve(potAddress,price);
        console.log(result);

      } else {       
      }
    } catch (error) {
      console.log(error)
    }
  }

<button className="mintButton" onClick={()  => pot()}>thing</button>
*/
  //////////////////////////////////
  return (
    <>
    <div className="mainContainer">
      <div className="dataContainer">
        <div className="cms"><span>SHEEP!</span></div>
        {currentAccount && (
          <div className="dataTop">
            {visibleTitle && (
              <>
              <h2>SHEEP : {visibleTitle}!</h2>
              <h2>current price : {price} </h2>
              </>
            )}

            <div className="dataTop-action">
            {hideButton &&(
                <>
                    <button className="mintButton" onClick={()  => testing()}>test</button>
                    
                </>
              )}  

            {hideButton &&(
                <>
                    <button className="mintButton" onClick={()  => claimFLCE()}>claim FLCE</button>
                    
                </>
              )}  

            {hideButton &&(
                <>
                    <button className="mintButton" onClick={()  => mintOne('wolf')}>mint wolf</button>
                    
                </>
              )}  

              {hideButton &&(
                <>
                    <button className="mintButton" onClick={()  => mintOne('sheep')}>mint sheep</button>
                    #<input placeholder = "1" onChange={handleMintAmount}
                          onKeyPress={(event) => {
                            if (!/[0-9]/.test(event.key)) {
                              event.preventDefault();
                            }
                          }}
                    />
                </>
              )}    
            </div>
          </div>
        )}
        <div className="error">
          {errorMsg && (
            <h4>{errorMsg}</h4>
          )}
        </div>
        {!currentAccount && (
          <div className="dataBottom">
            <button className="waveButton" onClick={connectWallet}>Connect Wallet</button>
            <a href="https://metamask.io/download/" >don't have a metamask wallet? click here</a>
          </div> 
        )}
        {currentAccount && (
          <>
            <div className='nftDisplay'>

              {imagesWolf.map((imagesWolf,index)=> (
                  
                    <div className='nft' key={index}>
                    <>
                      <div className='token' >
                        <img  src={imagesWolf} />
                         
                      </div>
                      <div className="nftname" >
                        {namesWolf[index]}
                      </div>
                      </>
                    </div>
                ))}
            </div>
            <div className='nftDisplay'>

                {imagesSheep.map((imagesSheep,index)=> (
                  
                    <div className='nft' key={index}>
                    <>
                      <div className='token' >
                        <img  src={imagesSheep} />
                         
                      </div>
                      <div className="nftname" >
                        {namesSheep[index]}
                      </div>
                      </>
                    </div>
                ))}

                 
                
            </div>
          </>
        )}
        {voteAvailable && (
                <>   
                  <div className='votearea'>        
                    <div className="error">
                        <h4>CMSIP-2 : Extend and Expand Whitelist to disperse Flock? <a target="_blank" href="https://discord.com/channels/948244056209768458/1006996591036608512/1011381014381207604">details</a></h4>
                    </div>     
                    <button className="voteButton" onClick={()  => castVote(true)}>YES!</button>
                    <button className="voteButton" onClick={()  => castVote(false)}>NO!</button>
                    {voteMsg &&(
                      <h4>{voteMsg}</h4>
                      )}
                  </div>
                </>
              )}
      </div>
    </div>
    <div className="bottom">
      
      {sheepContractAddress && (
        <h3>contract : {sheepContractAddress}</h3>
      )}
    </div>   
  </>
  );
}