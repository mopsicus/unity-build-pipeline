using System.Collections;
using System.Collections.Generic;
using NUnit.Framework;
using UnityEngine;

public class DemoTest : MonoBehaviour {

    [Test]
    public void TestBad () {
        Assert.AreEqual (1, 2);
    }

    [Test]
    public void TestGood () {
        Assert.AreEqual (1, 1);
    }

#if DEV 
    public void OnlyDevMethod () {
        Debug.Log ("This method will be in developer build");
    }
#endif
}