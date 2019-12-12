using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEngine;

namespace Game {

	/// <summary>
	/// Proccess data after build
	/// </summary>
	public class PostBuildActions {

		/// <summary>
		/// Run after project build
		/// </summary>
		/// <param name="buildTarget">Platform</param>
		/// <param name="path">Path to folder</param>
		[PostProcessBuild]
		public static void PostProcess (BuildTarget buildTarget, string pathToBuiltProject) {
			byte[] data = Encoding.UTF8.GetBytes (Application.version);
			string path = Path.Combine (Directory.GetParent (Application.dataPath).FullName, "SupportFiles", "version.txt");
			if (File.Exists (path)) {
				File.Delete (path);
			}
			File.WriteAllBytes (path, data);
		}
	}
}