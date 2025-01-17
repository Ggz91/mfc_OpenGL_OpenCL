//__constant float3 cf3LightPos = (float3)(7, 0, 0);
__constant float  cfMouseSpeed = 0.01f;
//__constant float3 f3EyePos = (float3)(0, 0, 7.0);
//__constant int MAXITER = 1;

struct TriangleCandidateSplitPlane
{
	int triangleID;
	float xMin;
	float yMin;
	float zMin;
	float xMax;
	float yMax;
	float zMax;
};

struct SplitNode
{
	int beg;
	int end;
	int leftChild;
	int rightChild;
	
	float xMin;
	float xMax;
	float yMin;
	float yMax;
	float zMin;
	float zMax;
	
};



//用于矩阵的运算，转换坐标系用
struct mat4
{
	float4 l0;
	float4 l1;
	float4 l2;
	float4 l3;

	
};

struct t
{
	float txMax;
	float txMin;
	float tyMax;
	float tyMin;
	float tzMax;
	float tzMin;

	
};

//SAA参数
struct SAAParam 
{
	float originTmp;
	float SAASingleSampleCount;
	float descSpeed;
};

//PSO参数
struct PSOParam
{
	float particleNum;
	float PSOSampleCount;
	float inertiaWeight;
	float c1Weight;
	float c2Weight;
	float singleMaxShift;
	int 	maxLength;
};

bool bCross(struct t stT, float* tMin, float* tMax)
{
	
	if((stT.txMax < stT.tyMin) || (stT.tyMax < stT.txMin)) return false;

	*tMin = (stT.txMin < stT.tyMin) ? stT.txMin : stT.tyMin;
	*tMax = (stT.txMax > stT.tyMax) ? stT.txMax : stT.tyMax;

	if((*tMax < stT.tzMin) || (stT.tzMax < *tMin)) return false;

	*tMin = (*tMin > stT.tzMin) ? stT.tzMin : *tMin ;
	*tMax = (*tMax < stT.tzMax) ? stT.tzMax : *tMax ;

	return true;

	

};

struct cusVec3
{
	float x;
	float y;
	float z;
};

struct TriangleInfo
{
	int triangleID;

	struct cusVec3 vecInfo[3];

	struct cusVec3 vecNormal;
};

bool bIntersect(struct TriangleInfo sTri,float3 f3EyePos, float3 f3LightDir,float* tMin, float* tMax, float3* interPos)
{
	float3 f3Nor = (float3) (sTri.vecNormal.x, sTri.vecNormal.y, sTri.vecNormal.z);
	if(dot( f3Nor, f3LightDir)  > 0) return false;

	float a1 = f3LightDir.x;
	float a2 = f3LightDir.y;
	float a3 = f3LightDir.z;
	float b1 = sTri.vecInfo[0].x - sTri.vecInfo[1].x;
	float b2 = sTri.vecInfo[0].y - sTri.vecInfo[1].y;
	float b3 = sTri.vecInfo[0].z - sTri.vecInfo[1].z;
	float c1 = sTri.vecInfo[0].x - sTri.vecInfo[2].x;
	float c2 = sTri.vecInfo[0].y - sTri.vecInfo[2].y;
	float c3 = sTri.vecInfo[0].z - sTri.vecInfo[2].z;
	float d1 = sTri.vecInfo[0].x - f3EyePos.x;
	float d2 = sTri.vecInfo[0].y - f3EyePos.y;
	float d3 = sTri.vecInfo[0].z - f3EyePos.z;
	/*float detA = a1*b2*c3 + b1*c2*a3 + c1*a2*b3 - (c1*b2*a3 + b1*a2*c3 + a1*c2*b3);
	float detA1 = c1*b2*d3 + b1*d2*c3 + d1*c2*b3 - (d1*b2*c3 + b1*c2*d3 + c1*d2*b3);
	float detA2 = c1*d2*a3 + d1*a2*c3 + a1*c2*d3 - (a1*d2*c3 + d1*c2*a3 + c1*a2*d3);
	float detA3 = d1*b2*a3 + b1*a2*d3 + a1*d2*b3 - (a1*b2*d3 + b1*d2*a3 + d1*a2*b3);*/
	float detA = a1*(b2*c3 - b3*c2) - b1*(a2*c3 - a3*c2) + c1*(a2*b3 - a3*b2);
	float detA1 = d1*(b2*c3 - b3*c2) - b1*(d2*c3 - d3*c2) + c1*(d2*b3 - d3*b2);
	float detA2 = a1*(d2*c3 - d3*c2) - d1*(a2*c3 - a3*c2) + c1*(a2*d3 - a3*d2);
	float detA3 = a1*(b2*d3 - b3*d2) - b1*(a2*d3 - a3*d2) + d1*(a2*b3 - a3*b2);
	//printf("%f %f %f %f %f %f %f %f %f %f %f %f %f %f", a1, a2, a3, b1, b2, b3, c1, c2, c3, d1, d2, d3);
	//printf("%f %f %f %f", detA, detA1, detA2, detA3);

	if( 0==detA ) 
	{
		return false;
	}

	float t = detA1 / detA; 
	float b = detA2 / detA;
	float c = detA3 / detA;

	

	if( ( t<=(*tMin) ) || ( t>=(*tMax) )) return false;
	if( ( c>1 ) || ( c<0 )) return false;
	if( ( b>1-c ) || ( b<0 )) return false;
	
	interPos->x = f3EyePos.x + t * f3LightDir.x;
	interPos->y = f3EyePos.y + t * f3LightDir.y;
	interPos->z = f3EyePos.z + t * f3LightDir.z;
	
	
	
	return true;
}	

float3 reflect(float3 V, float3 N)
{
	return V - 2.0f * dot( V, N ) * N;
}

float4  mul(struct mat4 m4, float4 l)
{
	float4 res;
	res.x = m4.l0.x*l.x + m4.l0.y*l.y + m4.l0.z*l.z + m4.l0.w*l.w;
	res.y = m4.l1.x*l.x + m4.l1.y*l.y + m4.l1.z*l.z + m4.l1.w*l.w;
	res.z = m4.l2.x*l.x + m4.l2.y*l.y + m4.l2.z*l.z + m4.l2.w*l.w;
	res.w = m4.l3.x*l.x + m4.l3.y*l.y + m4.l3.z*l.z + m4.l3.w*l.w;

	return res;
		
};

uchar3 uc3MulFloat(uchar3 opa, float opb)
{
	uchar3 res;
	res.x = opa.x * opb;
	res.y = opa.y * opb;
	res.z = opa.z * opb;
	//res.w = res.w * opb;
	return res;
}

void UpdateSplitNodeWithAABBInfo(__global struct SplitNode *nodeArray,
								 int idx, 
								__global const struct TriangleCandidateSplitPlane *input)
{
	for(int i = nodeArray[idx].beg + 1; i <=  nodeArray[idx].end; i++)
	{
		 nodeArray[idx].xMin = ( nodeArray[idx].xMin < input[i].xMin)?  (nodeArray[idx].xMin):(input[i].xMin);
		 nodeArray[idx].xMax = ( nodeArray[idx].xMax > input[i].xMax)?  (nodeArray[idx].xMax):(input[i].xMax);
		 nodeArray[idx].yMin = ( nodeArray[idx].yMin < input[i].yMin)?  (nodeArray[idx].yMin):(input[i].yMin);
		 nodeArray[idx].yMax = ( nodeArray[idx].yMax > input[i].yMax)?  (nodeArray[idx].yMax):(input[i].yMax);
		 nodeArray[idx].zMin = ( nodeArray[idx].zMin < input[i].zMin)?  (nodeArray[idx].zMin):(input[i].zMin);
		 nodeArray[idx].zMax = ( nodeArray[idx].zMax > input[i].zMax)?  (nodeArray[idx].zMax):(input[i].zMax);
	}
}

float ComputeSAH(int pos, __global struct SplitNode* nodeArray, int idx,__global const struct  TriangleCandidateSplitPlane* input)
{
		int lNum = pos - nodeArray[idx].beg;
		int rNum = nodeArray[idx].end - lNum + 1;
		//float  wholeSurfaceArea = 2.0*(nodeArray[idx].xMax -  nodeArray[idx].xMin)
		//						 *(nodeArray[idx].yMax - nodeArray[idx].yMin) 
		//						 + 2.0*(nodeArray[idx].xMax - nodeArray[idx].xMin)
		//						 *(nodeArray[idx].zMax - nodeArray[idx].zMin)
		//						 + 2.0*(nodeArray[idx].zMax - nodeArray[idx].zMin)
		//						 *(nodeArray[idx].yMax - nodeArray[idx].yMin);
		//float leftSurfaceArea = 2.0*(input[pos].xMin -  nodeArray[idx].xMin)
		//						 *(nodeArray[idx].yMax - nodeArray[idx].yMin) 
		//						 + 2.0*(input[pos].xMin - nodeArray[idx].xMin)
		//						 *(nodeArray[idx].zMax - nodeArray[idx].zMin)
		//						 + 2.0*(nodeArray[idx].zMax - nodeArray[idx].zMin)
		//						 *(nodeArray[idx].yMax - nodeArray[idx].yMin);
		//float rightSurfaceArea = 2.0*(nodeArray[idx].xMax -  input[pos].xMin)
		//						 *(nodeArray[idx].yMax - nodeArray[idx].yMin) 
		//						 + 2.0*(nodeArray[idx].xMax - input[idx].xMin)
		//						 *(nodeArray[idx].zMax - nodeArray[idx].zMin)
		//						 + 2.0*(nodeArray[idx].zMax - nodeArray[idx].zMin)
		//						 *(nodeArray[idx].yMax - nodeArray[idx].yMin);
		//
		//float SAH = (lNum*leftSurfaceArea + rNum*rightSurfaceArea) / wholeSurfaceArea;
		//return SAH;


		float fLW = nodeArray[idx].xMax - nodeArray[idx].xMin;
		float fWW = nodeArray[idx].yMax - nodeArray[idx].yMin;
		float fHW = nodeArray[idx].zMax - nodeArray[idx].zMin;

		float fLL = input[pos].xMin - nodeArray[idx].xMin;
		float fLR = nodeArray[idx].xMax - input[pos].xMin;

		float fLeftArea = 2.0*fLL*fHW + 2.0*fLL*fWW + fWW*fHW;
		float fRightArea = 2.0*fLR*fHW + 2.0*fLR*fWW + fWW*fHW;
		float fArea = 2.0* fLW*fHW + 2.0*fLW*fWW + 2*fWW*fHW;
		float SAH = (lNum*fLeftArea + rNum*fRightArea) / fArea;
		return SAH;		
}

__kernel void BitonicSort (__global struct TriangleCandidateSplitPlane* input,  
                         __global const int* group,  
                         __global const int* length,  
                         __global const int* dir,  
                         __global const int* flip)  
{  
    int bid = get_group_id(0);  
    int groupsInKernel = get_num_groups(0);  
    int wid = get_local_id(0);  
    int itemsInGroup = get_local_size(0);  
      
    for(int gpos = bid; gpos < (*group); gpos += groupsInKernel)
	{  
        for(int pos = wid; pos < (*length)/2; pos += itemsInGroup)
		{  
            int begin = gpos * (*length);  
            int delta;  
            if ((*flip) == 1)   delta = (*length) - 1;  
            else                delta = (*length)/2;  
              
            int a = begin + pos;  
            int b = begin + delta - (*flip) * pos;  
              
            if ( (*dir) == (input[a].xMin > input[b].xMin) )
			{  
                struct TriangleCandidateSplitPlane temp = input[a];  
                input[a] = input[b];  
                input[b] = temp;  
            }  
        }  
    }  
}



__kernel void SAHSplit(__global const struct TriangleCandidateSplitPlane* input,
						__global struct SplitNode*	splitNodeArray,
						__global const int* splitNodeArrayBeg,
						__global const int* splitNodeArrayEnd,
						__global const int* maxSize
						)
{
	int idx= get_global_id(0) + (*splitNodeArrayBeg);
	splitNodeArray[idx].xMax = input[splitNodeArray[idx].beg].xMax;
	splitNodeArray[idx].xMin = input[splitNodeArray[idx].beg].xMin;
	splitNodeArray[idx].yMax = input[splitNodeArray[idx].beg].yMax;
	splitNodeArray[idx].yMin = input[splitNodeArray[idx].beg].yMin;
	splitNodeArray[idx].zMax = input[splitNodeArray[idx].beg].zMax;
	splitNodeArray[idx].zMin = input[splitNodeArray[idx].beg].zMin;
	UpdateSplitNodeWithAABBInfo(splitNodeArray, idx, input);
	if((idx>= *splitNodeArrayBeg)&&(idx<= *splitNodeArrayEnd) && (splitNodeArray[idx].end - splitNodeArray[idx].beg > 64) && (splitNodeArray[idx].beg != -1) && (splitNodeArray[idx].end != -1))
	{
		
		
		int currentPos =  splitNodeArray[idx].beg;
		float currentSAH = ComputeSAH(currentPos, splitNodeArray, idx, input);
		
		float fTmpSAH;
		//printf("%f", currentSAH);
		for(int i = splitNodeArray[idx].beg + 1; i < splitNodeArray[idx].end; i++)
		{
			fTmpSAH = ComputeSAH(i, splitNodeArray, idx, input);

			if( fTmpSAH < currentSAH)
			{
				currentPos = i;
				currentSAH = fTmpSAH;
			}
		}
		
		splitNodeArray[idx*2 + 1].beg = splitNodeArray[idx].beg;
		splitNodeArray[idx*2 + 1].end = currentPos - 1;
		splitNodeArray[idx*2 + 2].beg = currentPos;
		splitNodeArray[idx*2 + 2].end = splitNodeArray[idx].end;
		
		if((idx*2 + 2) < *maxSize)
		{
			splitNodeArray[idx].leftChild = idx*2 + 1;
			splitNodeArray[idx].rightChild = idx*2 + 2;
			
		}
		/*else
		{
			splitNodeArray[idx].leftChild = *maxSize - 2;
			splitNodeArray[idx].rightChild = *maxSize - 1;
			splitNodeArray[splitNodeArray[idx].leftChild].beg = splitNodeArray[idx].beg;
			splitNodeArray[splitNodeArray[idx].leftChild].end = currentPos - 1;
			splitNodeArray[splitNodeArray[idx].rightChild].beg = currentPos;
			splitNodeArray[splitNodeArray[idx].rightChild].end = splitNodeArray[idx].end;
		}
		*/
	}
	//printf("\n");
}

__kernel void SAASAHSplit(__global const struct TriangleCandidateSplitPlane* input,
						__global struct SplitNode*	splitNodeArray,
						__global const int* splitNodeArrayBeg,
						__global const int* splitNodeArrayEnd,
						__global const int* randPos,
						__global const int* randPro,
						__global const int* maxSize,
						__global const struct SAAParam* param
						)
{
	int T0 = param->originTmp;
	int NMAX = param->SAASingleSampleCount;
	float DEC_SPEED = param->descSpeed;
	
	int idx= get_global_id(0) + (*splitNodeArrayBeg);
	//printf("Beg:%d\t\tEnd:%d\t\tID:%d\t\t\nnodeBeg:%d\t\tnodeEnd:%d\t\t\n", *splitNodeArrayBeg, *splitNodeArrayEnd, idx, splitNodeArray[idx].beg, splitNodeArray[idx].end);
	splitNodeArray[idx].xMax = input[splitNodeArray[idx].beg].xMax;
	splitNodeArray[idx].xMin = input[splitNodeArray[idx].beg].xMin;
	splitNodeArray[idx].yMax = input[splitNodeArray[idx].beg].yMax;
	splitNodeArray[idx].yMin = input[splitNodeArray[idx].beg].yMin;
	splitNodeArray[idx].zMax = input[splitNodeArray[idx].beg].zMax;
	splitNodeArray[idx].zMin = input[splitNodeArray[idx].beg].zMin;
	UpdateSplitNodeWithAABBInfo(splitNodeArray, idx, input);
		
	if((idx>= *splitNodeArrayBeg)&&(idx<= *splitNodeArrayEnd) && (splitNodeArray[idx].end - splitNodeArray[idx].beg > 64) && (splitNodeArray[idx].beg != -1) && (splitNodeArray[idx].end != -1))
	{
		
		int i = 0;
		int j = 0;
		int currentPos = randPos[i++] % ((splitNodeArray[idx].end) - (splitNodeArray[idx].beg) + 1) + splitNodeArray[idx].beg;
		float currentSAH = ComputeSAH(currentPos, splitNodeArray, idx, input);
		
		//printf("Beg:%d\t\tEnd:%d\t\tID:%d\t\t\nnodeBeg:%d\t\tnodeEnd:%d\t\t\n", *splitNodeArrayBeg, *splitNodeArrayEnd, globalID, splitNodeArray[globalID].beg, splitNodeArray[globalID].end);
		//printf("before:\nrandPos:%d\t\tcurrentPos:%d\t\tcurrentSAH:%f\n",randPos[i-1], currentPos, currentSAH);
		int T = T0;
		int maxNum = 0;
		maxNum = (splitNodeArray[idx].end - splitNodeArray[idx].beg + 1) * log(1 - DEC_SPEED)/ log( 20.0 ) ;
		maxNum /= 3;
		while(T > 1)
		{
			int n = 0;
			while(n < maxNum)
			{
				int newPos = randPos[i++] % ((splitNodeArray[idx].end) - (splitNodeArray[idx].beg) + 1) + splitNodeArray[idx].beg;
				float newSAH = ComputeSAH(newPos, splitNodeArray, idx, input);

				if(newSAH < currentSAH)
				{
					currentPos = newPos;
					currentSAH = newSAH;
				}
				else
				{
					float r = exp(-(newSAH - currentSAH) / T);
					if(randPro[j++] < r)
					{
						currentPos = newPos;
						currentSAH = newSAH;
					}
				}//endif(newSAH < currentSAH)
				n++;
			}//end while(n<8)
			T = (1-DEC_SPEED)*T;
		}//end while(T > 1)

		//printf("after:\nrandPos:%d\t\tcurrentPos:%d\t\tcurrentSAH:%f\n",randPos[i-1], currentPos, currentSAH);

		//printf("%d", currentPos);

		splitNodeArray[idx*2 + 1].beg = splitNodeArray[idx].beg;
		splitNodeArray[idx*2 + 1].end = currentPos - 1;
		splitNodeArray[idx*2 + 2].beg = currentPos;
		splitNodeArray[idx*2 + 2].end = splitNodeArray[idx].end;
		if((idx*2 + 2) < *maxSize)
		{
			splitNodeArray[idx].leftChild = idx*2 + 1;
			splitNodeArray[idx].rightChild = idx*2 + 2;
		}
		
	}
	//printf("\n");
}

__kernel void PSOSAHSplit(__global struct TriangleCandidateSplitPlane* input,
						__global struct SplitNode*	splitNodeArray,
						__global const int* splitNodeArrayBeg,
						__global const int* splitNodeArrayEnd,
						__global const int* randPos,
						__global const int* randPro,
						__global const int* maxSize,
						__global const struct PSOParam* param,
					  __local	int* adX,
						__local float* adY,
						__local float* adV,
						__local float* adBest
						)
{
	int ciParticleNum = param->particleNum;
	int ciMax = param->PSOSampleCount;
	float dC1 = param->c1Weight;
	float dC2 = param->c2Weight;
	float cdVmax = param->singleMaxShift;
	float dW = param->inertiaWeight;
	int len = param->maxLength;
	
	int idx= get_global_id(0) + (*splitNodeArrayBeg);
	
	//printf("Beg:%d\t\tEnd:%d\t\tID:%d\t\t\nnodeBeg:%d\t\tnodeEnd:%d\t\t\n", *splitNodeArrayBeg, *splitNodeArrayEnd, idx, splitNodeArray[idx].beg, splitNodeArray[idx].end);
	splitNodeArray[idx].xMax = input[splitNodeArray[idx].beg].xMax;
	splitNodeArray[idx].xMin = input[splitNodeArray[idx].beg].xMin;
	splitNodeArray[idx].yMax = input[splitNodeArray[idx].beg].yMax;
	splitNodeArray[idx].yMin = input[splitNodeArray[idx].beg].yMin;
	splitNodeArray[idx].zMax = input[splitNodeArray[idx].beg].zMax;
	splitNodeArray[idx].zMin = input[splitNodeArray[idx].beg].zMin;
	UpdateSplitNodeWithAABBInfo(splitNodeArray, idx, input);
	if((idx>= *splitNodeArrayBeg)&&(idx<= *splitNodeArrayEnd) && (splitNodeArray[idx].end - splitNodeArray[idx].beg > 64) && (splitNodeArray[idx].beg != -1) && (splitNodeArray[idx].end != -1))
	{
		
		
		int iPos = 0;
		int jPos = 0;
		int currentPos = randPos[iPos++] % ((splitNodeArray[idx].end) - (splitNodeArray[idx].beg) + 1) + splitNodeArray[idx].beg;
		float currentSAH = ComputeSAH(currentPos, splitNodeArray, idx, input);
		
		
		//粒子群算法
		/*int* adX;
		float* adY;
		float* adV;
		float* adBest;
		
		adX = (int*)local_malloc(ciParticleNum*sizeof(int));
		adY = (float*)local_malloc(ciParticleNum*sizeof(float));
		adV = (float*)local_malloc(ciParticleNum*sizeof(float));
		adBest = (float*)local_malloc(ciParticleNum*sizeof(float));*/
		//初始化
		/*for( int i = 0; i<ciParticleNum; i++ )
		{
			if( iPos >= len ) iPos %= len;
			
			adX[i] = randPos[iPos++] % ((splitNodeArray[idx].end) - (splitNodeArray[idx].beg) + 1) + splitNodeArray[idx].beg;
			adY[i] = ComputeSAH(adX[i], splitNodeArray, idx, input);
			adBest[i] = adY[i];
			if( adY[i] < currentSAH ) 
			{
				currentSAH = adY[i];
				currentPos = adX[i];
			}
		}		

		int maxLayer = (splitNodeArray[idx].end - splitNodeArray[idx].beg+1)/ciParticleNum;
		maxLayer /= 6;
		//for( int i = 0 ; i<ciMax; i++)
		for( int i = 0; i<maxLayer; i++)
		{
			for( int j = 0; j<ciParticleNum; j++)
			{
				if( iPos >= len ) iPos %= len;
				adV[j] = dW*adV[j] + dC1*randPro[iPos++]*(adBest[j] - adX[j] ) + dC2*randPro[iPos]*(adBest[j]-adX[j]);

				if( adV[j] > cdVmax ) adV[j] = cdVmax;
				if( adV[j] < -cdVmax) adV[j] = -cdVmax;
				adX[j] += adV[j];
				if( adX[j] > *splitNodeArrayEnd) adX[j] = *splitNodeArrayEnd;
				if( adX[j] < *splitNodeArrayBeg) adX[j] = *splitNodeArrayBeg;

				adY[i] = ComputeSAH(adX[i], splitNodeArray, idx, input);
				adBest[i] = (adY[i]<adBest[i]) ? adY[i] : adBest[i];
				if( adBest[i] != adY[i] ) adX[j] -= adV[j];


			}

			for( int i = 0; i<ciParticleNum; i++ )
			{
				
				if( adBest[i] < currentSAH ) 
				{
					currentSAH = adBest[i];
					currentPos = adX[i];
				}	

			}	
		}

			


		splitNodeArray[idx*2 + 1].beg = splitNodeArray[idx].beg;
		splitNodeArray[idx*2 + 1].end = currentPos - 1;
		splitNodeArray[idx*2 + 2].beg = currentPos;
		splitNodeArray[idx*2 + 2].end = splitNodeArray[idx].end;

		if((idx*2 + 2) < *maxSize)
		{
			splitNodeArray[idx].leftChild = idx*2 + 1;
			splitNodeArray[idx].rightChild = idx*2 + 2;
		}
		*/
	}
	//printf("\n");
}


//遍历叶子节点的三角面片
uchar3 RayCrossTraingleTest(struct SplitNode node, 
														float3 f3EyePos,
														float3 cf3LightPos, 
														float3 f3LightDir, 
														float* fDst,
														__global  struct TriangleInfo* TriangleInfoArray, 
														__global struct TriangleCandidateSplitPlane* input, 
														float* tMin, 
														float* tMax, 
														float3* f3NextPos, 
														float3* f3NextDir, 
														float* cosAl, 
														int* flag)
{
	float3 f3Res = (float3)(153, 51, 250);
	uchar3 uc3Res = (uchar3)(153, 51, 250);
	float3 f3InterPos;
	float3 R;
	float  cosAlpha;
	int	   iInBox =1;

	for(int i=node.beg; (i<=node.end) && (iInBox == 1); i++)
	{	
		int idx = input[i].triangleID;
		if( bIntersect(TriangleInfoArray[idx], f3EyePos, f3LightDir, tMin, tMax, &f3InterPos) )
		{
			float3 f3LightColor = (float3)( 1, 1, 1);
			float fLightPower = 50;
			float3 f3MaterialDiffuseColor = (float3)(100, 100, 100);
			float3 f3MaterialAmbientColor = (float3)(0.1, 0.1, 0.1)* f3MaterialDiffuseColor;
			float3 f3MaterialSpecularColor = (float3)(0.3, 0.3, 0.3);
			float fDistPosToLight = distance(f3InterPos, cf3LightPos);
			float fDistPosToEye = distance(f3InterPos, f3EyePos);

			if( 0 == fDistPosToEye ) 
			{	
				iInBox = 0;
				break;
			}
			/*if( fDistPosToEye > *fDst)	
			{
				
				break;
			}*/
			
			
			*fDst = fDistPosToEye;
			
			float3 f3Normal = (float3)(TriangleInfoArray[idx].vecNormal.x, TriangleInfoArray[idx].vecNormal.y, TriangleInfoArray[idx].vecNormal.z);
			
			float3 f3LightDirWS = f3InterPos - cf3LightPos;

			float3 n = normalize( f3Normal );
			float3 l = normalize( f3LightDir );
			float fTmp = dot(n,l);
			float cosTheta = clamp( fTmp, (float) -1.0, (float) 0.0);

			float3 E = normalize( f3LightDirWS);
			R = reflect( l, n);
			fTmp= dot(E, R);
			cosAlpha = clamp(fTmp, (float) 0.0, (float) 1.0);

			f3Res = f3MaterialAmbientColor +
					f3MaterialDiffuseColor * f3LightColor * fLightPower * fabs(cosTheta) / (fDistPosToLight * fDistPosToLight) + 
					f3MaterialSpecularColor * f3LightColor * fLightPower * pow(cosAlpha, 5) / (fDistPosToEye * fDistPosToEye);

			*flag = 1;
		}
	}

	if( 1 == *flag)
	{
		*f3NextPos = f3InterPos;
		*f3NextDir = R;
		*cosAl = cosAlpha; 
	}

	uc3Res = (uchar3)(f3Res.x, f3Res.y, f3Res.z);
	
	return uc3Res;
	
}


//创建栈
struct Stack
{
	int		top;
	int		size;
	struct	SplitNode ssMemNode[5000];

};

void InitStack(struct Stack* sSt, int size)
{
	sSt->size = size;
	sSt->top = 0;
}

void PushStack(struct Stack* sSt, struct SplitNode sSN)
{

	int idx = sSt->top;
	if( sSt->size <= idx)
	{
		printf("the top is beyond the size of stack ");
	}
	sSt->ssMemNode[idx] = sSN;
	sSt->top++;
}

struct SplitNode PopStack(struct Stack* sSt)
{
	int idx = sSt->top - 1;
	if( 0 == sSt->top)
	{
		printf("the top of Stack is zero");
	}
	struct SplitNode sRes = sSt->ssMemNode[idx];
	sSt->top--;
	return sRes;
}

bool IsEmpty(struct Stack* sSt)
{

	if( 0==sSt->top ) 
	{
		return true;
	}
	return false;
}


uchar3 RayCrossAABBTest(struct SplitNode root, float3 f3EyePos, float3 cf3LightPos, float3 f3LightDir,__global const struct SplitNode* spSplitNodeArray, __global struct TriangleInfo* TriangleInfoArray, __global struct TriangleCandidateSplitPlane* input, float* tMin, float* tMax, __global const int* length, float3* f3NextPos, float3* f3NextDir, float* cosAlpha, int* flag)
{
	
	//背景颜色
	uchar3 f3Res = (uchar3)(8, 46, 84);
	////判断是不是最终的叶子节点
	//if( (root.leftChild == -1 ) && (root.rightChild == -1)) 
	//{
	//	f3Res = RayCrossTraingleTest(root, f3EyePos, f3LightDir, fDst, TriangleInfoArray, input, tMin, tMax);
	//	return f3Res;
	//}

	//struct t sT;
	//sT.txMax = (root.xMax - f3EyePos.x)/f3LightDir.x;
	//sT.txMin = (root.xMin - f3EyePos.x)/f3LightDir.x;
	//sT.tyMax = (root.yMax - f3EyePos.y)/f3LightDir.y;
	//sT.tyMin = (root.yMin - f3EyePos.y)/f3LightDir.y;
	//sT.tzMax = (root.zMax - f3EyePos.z)/f3LightDir.z;
	//sT.tzMin = (root.zMin - f3EyePos.z)/f3LightDir.z;

	//if( bCross(sT, tMin, tMax) )
	//{
	//	float fLeftDst, fRightDst;
	//	float3 f3LeftPixel = RayCrossAABBTest(spSplitNodeArray[root.leftChild], f3EyePos, f3LightDir, spSplitNodeArray, &fLeftDst, TriangleInfoArray, input, tMin, tMax);
	//	float3 f3RightPixel = RayCrossAABBTest(spSplitNodeArray[root.rightChild], f3EyePos, f3LightDir, spSplitNodeArray, &fRightDst, TriangleInfoArray, input, tMin, tMax);
	//	f3Res = (fLeftDst < fRightDst) ? f3LeftPixel : f3RightPixel;
	//}
	//else 
	//{
	//	//不经过当前包围盒的话，
	//	f3Res = (float3)(0, 0, 255);
	//	//fLeftDst = 10000;
	//}
	
	//层序遍历
	//struct Stack sStack;
	//InitStack(&sStack, (*length));
	//PushStack(&sStack, root);
	//int flag = 1;
	//while( !IsEmpty(&sStack) && ( flag == 1 ) )
	//{
	//	struct SplitNode snCurNode = PopStack(&sStack);
	//	//判断是否为叶子节点
	//	if( ( snCurNode.leftChild == -1) && (snCurNode.rightChild == -1) )
	//	{
	//		printf("in leaf node");
	//		f3Res = RayCrossTraingleTest( snCurNode, f3EyePos, f3LightDir, fDst, TriangleInfoArray, input, tMin, tMax, &flag);
	//		
	//	}
	//	else
	//	{
	//		struct t sT;
	//		sT.txMax = (snCurNode.xMax - f3EyePos.x)/f3LightDir.x;
	//		sT.txMin = (snCurNode.xMin - f3EyePos.x)/f3LightDir.x;
	//		sT.tyMax = (snCurNode.yMax - f3EyePos.y)/f3LightDir.y;
	//		sT.tyMin = (snCurNode.yMin - f3EyePos.y)/f3LightDir.y;
	//		sT.tzMax = (snCurNode.zMax - f3EyePos.z)/f3LightDir.z;
	//		sT.tzMin = (snCurNode.zMin - f3EyePos.z)/f3LightDir.z;
	//		if( bCross(sT, tMin, tMax))
	//		{
	//			//printf("%f %f", *tMin, *tMax);
	//			PushStack(&sStack, spSplitNodeArray[snCurNode.leftChild]);
	//			PushStack(&sStack, spSplitNodeArray[snCurNode.rightChild]);
	//		}
	//		
	//	}
	//}
	////printf("%d %d %d", f3Res.x, f3Res.y, f3Res.z);

	struct Stack sStack;
	InitStack(&sStack, (*length));
	PushStack(&sStack, root);
	float fLastDst = 10000;
	float fDst = 10000;
	while( !IsEmpty(&sStack) )
	{
		struct SplitNode snCurNode = PopStack(&sStack);
		struct t sT;
		
		float fTmp1, fTmp2;

		if( f3LightDir.x != 0 )
		{
			fTmp1 = (snCurNode.xMin - f3EyePos.x) / f3LightDir.x;
			fTmp2 = (snCurNode.xMax - f3EyePos.x) / f3LightDir.x;

			sT.txMin = (fTmp1 < fTmp2)? fTmp1 : fTmp2;
			sT.txMax = (fTmp1 >= fTmp2)? fTmp1 : fTmp2;
		}
		else
		{
			sT.txMin = 0;
			sT.txMax = 0;
		}
		

		if( f3LightDir.y != 0 )
		{
			fTmp1 = (snCurNode.yMin - f3EyePos.y) / f3LightDir.y;
			fTmp2 = (snCurNode.yMax - f3EyePos.y) / f3LightDir.y;

			sT.tyMin = (fTmp1 < fTmp2)? fTmp1 : fTmp2;
			sT.tyMax = (fTmp1 >= fTmp2)? fTmp1 : fTmp2;
		}
		else
		{
			sT.tyMin = 0;
			sT.tyMax = 0;
		}

		if( f3LightDir.z != 0 )
		{
			fTmp1 = (snCurNode.zMin - f3EyePos.z) / f3LightDir.z;
			fTmp2 = (snCurNode.zMax - f3EyePos.z) / f3LightDir.z;

			sT.tzMin = (fTmp1 < fTmp2)? fTmp1 : fTmp2;
			sT.tzMax = (fTmp1 >= fTmp2)? fTmp1 : fTmp2;
		}
		else
		{
			sT.tzMin = 0;
			sT.tzMax = 0;
		}

	
		
		
		
		while( (snCurNode.leftChild != -1) && (bCross(sT, tMin, tMax)) )
		{
			
			
			PushStack(&sStack, spSplitNodeArray[snCurNode.rightChild]);
			
			snCurNode = spSplitNodeArray[snCurNode.leftChild];
		
			if( (snCurNode.leftChild == -1) && (snCurNode.rightChild == -1)) break;

			if( f3LightDir.x != 0 )
			{
				fTmp1 = (snCurNode.xMin - f3EyePos.x) / f3LightDir.x;
				fTmp2 = (snCurNode.xMax - f3EyePos.x) / f3LightDir.x;

				sT.txMin = (fTmp1 < fTmp2)? fTmp1 : fTmp2;
				sT.txMax = (fTmp1 >= fTmp2)? fTmp1 : fTmp2;
			}
			else
			{
				sT.txMin = 0;
				sT.txMax = 0;
			}

			if( f3LightDir.y != 0 )
			{
				fTmp1 = (snCurNode.yMin - f3EyePos.y) / f3LightDir.y;
				fTmp2 = (snCurNode.yMax - f3EyePos.y) / f3LightDir.y;

				sT.tyMin = (fTmp1 < fTmp2)? fTmp1 : fTmp2;
				sT.tyMax = (fTmp1 >= fTmp2)? fTmp1 : fTmp2;
			}
			else
			{
				sT.tyMin = 0;
				sT.tyMax = 0;
			}

			if( f3LightDir.z != 0 )
			{
				fTmp1 = (snCurNode.zMin - f3EyePos.z) / f3LightDir.z;
				fTmp2 = (snCurNode.zMax - f3EyePos.z) / f3LightDir.z;

				sT.tzMin = (fTmp1 < fTmp2)? fTmp1 : fTmp2;
				sT.tzMax = (fTmp1 >= fTmp2)? fTmp1 : fTmp2;
			}
			else
			{
				sT.tzMin = 0;
				sT.tzMax = 0;
			}

		

		}

		if( ( snCurNode.leftChild == -1 ) && ( snCurNode.rightChild == -1 ))
		{
			uchar3 uc3Tmp = RayCrossTraingleTest( snCurNode, f3EyePos, cf3LightPos ,f3LightDir, &fDst, TriangleInfoArray, input, tMin, tMax, f3NextPos, f3NextDir, cosAlpha, flag);
			if( fDst < fLastDst)
			{
				f3Res = uc3Tmp;
				fLastDst = fDst;
			}
		}
	}
	
	return f3Res;

}

__kernel void RayTrace(__global const struct SplitNode* spSplitNodeArray, 
											__global const int* iWinWidth, 
											__global const int* iWinHeight, 
											__global unsigned char* pcResPB, 
											__global const struct TriangleInfo* TriangleInfoArray, 
											__global const struct TriangleCandidateSplitPlane* input, 
											__global const int*  length,
											__global const float* eyePos, 
											__global const float* lightPos,
											__global const int* iter,
											__global const double* xPos,
											__global const double* yPos
											)
{


	float tMin = 0;
	float tMax = 0;
	
	float3 f3EyePos = (float3)(eyePos[0], eyePos[1], eyePos[2]);
	float3 cf3LightPos = (float3)(lightPos[0], lightPos[1], lightPos[2]);
	
	int idx = get_global_id(0);
	
	int i = get_global_id(1);
	float3 f3PixPos = (float3)((idx - (*iWinWidth)/2.0  )/256.0 , ( i - (*iWinHeight)/2.0  )/256.0, 4.5);
	float fR =  fabs((f3PixPos - f3EyePos).z);
	//f3EyePos = (float3) ( *xPos/256, *yPos/256, f3EyePos.z);
	//float fDx = (idx - (*iWinWidth)/2.0) / 256.0;
	//float fDy = (i - (*iWinHeight)/2.0) / 256.0;
	float tanAlpha = (*yPos - (*iWinHeight)/2.0) / 256 * cfMouseSpeed ;
	float tanBeta = (*xPos - (*iWinWidth)/2.0) / 256 * cfMouseSpeed ;
	float sinAlpha = tanAlpha / sqrt(pown(tanAlpha,2) + 1);
	float cosAlpha = 1 / sqrt(pown(tanAlpha,2) + 1);
	float sinBeta = tanBeta / sqrt(pown(tanBeta, 2) + 1);
	float cosBeta = 1 / sqrt(pown(tanBeta, 2) + 1);
	
	

	float4 f4PixPos = (float4)(f3PixPos, 1);
	
	struct mat4 m4Trans1, m4Trans2;
	m4Trans1.l0 = (float4)(1, 0, 0, 0);
	m4Trans1.l1 = (float4)(0, 1, 0, 0);
	m4Trans1.l2 = (float4)(0, 0, 1, -1*fR);
	m4Trans1.l3 = (float4)(0, 0, 0, 1);

	m4Trans2.l0 = (float4)(1, 0, 0, 0);
	m4Trans2.l1 = (float4)(0, 1, 0, 0);
	m4Trans2.l2 = (float4)(0, 0, 1, fR);
	m4Trans2.l3 = (float4)(0, 0, 0, 1);

	struct mat4 m4RotaX, m4RotaY;
	m4RotaX.l0 = (float4)(1, 0, 0, 0);
	m4RotaX.l1 = (float4)(0, cosAlpha, sinAlpha, 0);
	m4RotaX.l2 = (float4)(0, -1*sinAlpha, cosAlpha, 0);
	m4RotaX.l3 = (float4)(0, 0, 0, 1);
	
	m4RotaY.l0 = (float4)(cosBeta, 0, sinBeta, 0);
	m4RotaY.l1 = (float4)(0, 1, 0, 0);
	m4RotaY.l2 = (float4)(-1*sinBeta, 0, cosBeta, 0);
	m4RotaY.l3 = (float4)(0, 0, 0, 1);

	f4PixPos = mul(m4Trans2, mul(m4RotaY, mul(m4RotaX, mul(m4Trans1, f4PixPos))));

	f3PixPos = f4PixPos.xyz;

	float3 f3Pos = f3EyePos;
	float3 f3LightDir = normalize(f3PixPos - f3EyePos);

	uchar3 f3Res = (uchar3)(8, 46, 84);
	int flag = 0;
	for(int i = 0; i< (*iter); i++)
	{
		
		if(isnan(f3LightDir.x) && i == 0)
		{
			printf("nan");
		}
		flag = 0;
		float3 f3NextPos;
		float3 f3NextDir;
		uchar3 uc3TmpColor;
		float cosAlpha;
		
		uc3TmpColor = RayCrossAABBTest(spSplitNodeArray[0], f3Pos, cf3LightPos, f3LightDir, spSplitNodeArray, TriangleInfoArray, input, &tMin, &tMax, length, &f3NextPos, &f3NextDir, &cosAlpha, &flag);
		
		if( 0 == flag)	break;//表示没有找到相交的三角面片
		if( 0 == i)
		{
			f3Res = uc3TmpColor;
		}
		else if( 0 != i)
		{
			float fDist = distance(f3Pos, f3NextPos);
			f3Res = f3Res + uc3MulFloat(uc3TmpColor, 50.0*cosAlpha / (fDist*fDist));
		}
		f3Pos = f3NextPos;
		f3LightDir = f3NextDir;
		

	}


	pcResPB[(i*(*iWinWidth)+idx)*4] = f3Res.x;
	pcResPB[(i*(*iWinWidth)+idx)*4 + 1] = f3Res.y;
	pcResPB[(i*(*iWinWidth)+idx)*4 + 2] = f3Res.z;
	pcResPB[(i*(*iWinWidth)+idx)*4 + 3] = 1;
	
	/*pcResPB[(i*(*iWinWidth)+idx)*4] = 255;
	pcResPB[(i*(*iWinWidth)+idx)*4 + 1] = 0;
	pcResPB[(i*(*iWinWidth)+idx)*4 + 2] = 0;
	pcResPB[(i*(*iWinWidth)+idx)*4 + 3] = 255;*/

}

/*__kernel void RayTrace(__global unsigned char* pRes)
{
	int idxX = get_global_id(0);
	int idxY = get_global_id(1);
	pRes[(idxY*1024+idxX)*4] = 0;
	pRes[(idxY*1024+idxX)*4+1] = 255;
	pRes[(idxY*1024+idxX)*4+2] = 0;
	pRes[(idxY*1024+idxX)*4+3] = 255;
}*/